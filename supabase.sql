-- =========================================================
-- DURGA SAMITI WEBSITE - UPGRADE SQL
-- Existing durga_members / durga_site_data / settings password are preserved.
-- Supabase Dashboard > SQL Editor > New Query > paste all > RUN
-- =========================================================

create extension if not exists pgcrypto with schema extensions;

-- 1) Existing member table: add new profile fields safely
create table if not exists public.durga_members (
  member_id text primary key check (member_id ~ '^[0-9]{10}$'),
  name text not null,
  created_at timestamptz not null default now()
);

alter table public.durga_members add column if not exists photo_url text;
alter table public.durga_members add column if not exists phone text;
alter table public.durga_members add column if not exists address text;
alter table public.durga_members add column if not exists birth_date date;
alter table public.durga_members add column if not exists position text;
alter table public.durga_members add column if not exists contribution numeric(12,2) not null default 0;
alter table public.durga_members add column if not exists active boolean not null default true;

-- 2) Existing shared website data (old notices and data remain in place)
create table if not exists public.durga_site_data (
  id integer primary key check (id = 1),
  data jsonb not null default '{"notices":[],"income":0,"expense":0}'::jsonb,
  updated_at timestamptz not null default now()
);

insert into public.durga_site_data(id, data)
values (1, '{"notices":[],"income":0,"expense":0,"bills":{},"gallery":[],"logo_url":""}'::jsonb)
on conflict (id) do nothing;

-- 3) Settings password table remains unchanged. First setup only inserts it.
create table if not exists public.durga_settings_secret (
  id integer primary key check (id = 1),
  password_hash text not null
);
insert into public.durga_settings_secret(id, password_hash)
values (1, extensions.crypt('AK@2026#£', extensions.gen_salt('bf')))
on conflict (id) do nothing;

-- 4) Read permissions: members and public site data are visible to all visitors
alter table public.durga_members enable row level security;
alter table public.durga_site_data enable row level security;
alter table public.durga_settings_secret enable row level security;

drop policy if exists "public read member directory" on public.durga_members;
create policy "public read member directory" on public.durga_members
for select to anon, authenticated using (true);

drop policy if exists "public read samiti data" on public.durga_site_data;
create policy "public read samiti data" on public.durga_site_data
for select to anon, authenticated using (true);

revoke all on public.durga_members from anon, authenticated;
grant select on public.durga_members to anon, authenticated;
revoke all on public.durga_site_data from anon, authenticated;
grant select on public.durga_site_data to anon, authenticated;
revoke all on public.durga_settings_secret from anon, authenticated;

-- 5) Check the existing Settings password (the existing password is not reset)
create or replace function public.durga_check_settings_password(p_password text)
returns boolean
language sql
security definer
set search_path = public, extensions
as $$
  select exists (
    select 1 from public.durga_settings_secret
    where id = 1 and password_hash = extensions.crypt(p_password, password_hash)
  );
$$;

-- 6) Save member profile + annual accounts + gallery + logo + notices
-- This replaces the old save function but keeps the same RPC name/arguments.
create or replace function public.durga_save_all(
  p_password text,
  p_members jsonb,
  p_data jsonb
)
returns boolean
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  ok boolean;
begin
  select exists (
    select 1 from public.durga_settings_secret
    where id = 1 and password_hash = extensions.crypt(p_password, password_hash)
  ) into ok;

  if not ok then return false; end if;
  if jsonb_typeof(p_members) <> 'array' or jsonb_typeof(p_data) <> 'object' then
    raise exception 'Invalid data format';
  end if;

  if exists (
    select 1 from jsonb_to_recordset(p_members) as x(name text, member_id text)
    where coalesce(trim(name), '') = '' or member_id !~ '^[0-9]{10}$'
  ) then raise exception 'Every member needs a name and 10 digit ID'; end if;

  if (select count(*) from jsonb_to_recordset(p_members) as x(name text, member_id text)) <>
     (select count(distinct member_id) from jsonb_to_recordset(p_members) as x(name text, member_id text))
  then raise exception 'Duplicate Member ID'; end if;

  delete from public.durga_members;
  insert into public.durga_members
    (name, member_id, photo_url, phone, address, birth_date, position, contribution, active)
  select trim(x.name), x.member_id, nullif(x.photo_url, ''), nullif(x.phone, ''),
         nullif(x.address, ''), nullif(x.birth_date, '')::date, nullif(x.position, ''),
         coalesce(x.contribution, 0), coalesce(x.active, true)
  from jsonb_to_recordset(p_members) as x(
    name text, member_id text, photo_url text, phone text, address text,
    birth_date text, position text, contribution numeric, active boolean
  );

  insert into public.durga_site_data(id, data, updated_at)
  values (1, p_data, now())
  on conflict (id) do update set data = excluded.data, updated_at = now();

  return true;
end;
$$;

revoke all on function public.durga_check_settings_password(text) from public;
revoke all on function public.durga_save_all(text, jsonb, jsonb) from public;
grant execute on function public.durga_check_settings_password(text) to anon, authenticated;
grant execute on function public.durga_save_all(text, jsonb, jsonb) to anon, authenticated;

-- 7) Group chat table. Members can read; sending is allowed only through RPC.
create table if not exists public.durga_chat_messages (
  id bigint generated by default as identity primary key,
  member_id text not null check (member_id ~ '^[0-9]{10}$'),
  member_name text not null,
  message text not null check (char_length(message) between 1 and 1500),
  created_at timestamptz not null default now()
);

alter table public.durga_chat_messages enable row level security;
drop policy if exists "public read samiti group chat" on public.durga_chat_messages;
create policy "public read samiti group chat" on public.durga_chat_messages
for select to anon, authenticated using (true);
revoke all on public.durga_chat_messages from anon, authenticated;
grant select on public.durga_chat_messages to anon, authenticated;

create or replace function public.durga_send_chat_message(
  p_member_id text,
  p_member_name text,
  p_message text
)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  new_id bigint;
begin
  if p_member_id !~ '^[0-9]{10}$' or char_length(trim(coalesce(p_message,''))) = 0
     or char_length(p_message) > 1500 then
    raise exception 'Invalid member ID or message';
  end if;

  if not exists (
    select 1 from public.durga_members
    where member_id = p_member_id and name = p_member_name and active = true
  ) then
    raise exception 'Active member not found';
  end if;

  insert into public.durga_chat_messages(member_id, member_name, message)
  values (p_member_id, p_member_name, trim(p_message))
  returning id into new_id;
  return new_id;
end;
$$;

revoke all on function public.durga_send_chat_message(text, text, text) from public;
grant execute on function public.durga_send_chat_message(text, text, text) to anon, authenticated;

-- 8) Enable Realtime for members, website data and group chat
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname='supabase_realtime' AND schemaname='public' AND tablename='durga_members') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.durga_members;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname='supabase_realtime' AND schemaname='public' AND tablename='durga_site_data') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.durga_site_data;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname='supabase_realtime' AND schemaname='public' AND tablename='durga_chat_messages') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.durga_chat_messages;
  END IF;
END $$;

-- IMPORTANT:
-- 1) Existing members, notices, and Settings password are preserved.
-- 2) The initial Settings password is AK@2026#£ only if the secret row did not exist.
-- 3) Member name + ID is a convenience login, not strong identity verification.
-- 4) Anyone who knows the shared Settings password can edit all site information.
-- 5) Gallery photos and member photos are added by direct image URL in this version.
-- =========================================================
