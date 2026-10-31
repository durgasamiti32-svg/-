-- Durga Samiti: shared website data + member authentication
-- Run the entire file in Supabase SQL Editor.
-- This design uses RLS. Do NOT disable RLS.

create table if not exists public.durga_member_accounts (
  auth_user_id uuid primary key references auth.users(id) on delete cascade,
  member_id text not null unique,
  is_admin boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.durga_app_state (
  id integer primary key check (id = 1),
  data jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.durga_member_accounts enable row level security;
alter table public.durga_app_state enable row level security;

-- The app only reads its own account mapping. Account mappings are managed
-- by the project owner in SQL Editor; no browser-side write policy is granted.
drop policy if exists "member can read own mapping" on public.durga_member_accounts;
create policy "member can read own mapping"
on public.durga_member_accounts for select
to authenticated
using (auth_user_id = auth.uid());

create or replace function public.durga_is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.durga_member_accounts
    where auth_user_id = auth.uid() and is_admin = true
  );
$$;

revoke all on function public.durga_is_admin() from public;
grant execute on function public.durga_is_admin() to authenticated;

drop policy if exists "signed in members can read shared data" on public.durga_app_state;
create policy "signed in members can read shared data"
on public.durga_app_state for select
to authenticated
using (true);

drop policy if exists "admins can create shared data" on public.durga_app_state;
create policy "admins can create shared data"
on public.durga_app_state for insert
to authenticated
with check (public.durga_is_admin());

drop policy if exists "admins can update shared data" on public.durga_app_state;
create policy "admins can update shared data"
on public.durga_app_state for update
to authenticated
using (public.durga_is_admin())
with check (public.durga_is_admin());

-- Enable Realtime for the shared state table (safe to run repeatedly).
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'durga_app_state'
  ) then
    alter publication supabase_realtime add table public.durga_app_state;
  end if;
end $$;

grant select, insert, update on public.durga_app_state to authenticated;
grant select on public.durga_member_accounts to authenticated;

-- IMPORTANT:
-- 1) Create each member in Supabase Dashboard > Authentication > Users.
-- 2) Use the synthetic email generated from the Member ID by supabase-sync.js:
--    member-<base64url(lowercase member id)>@durga-samiti.invalid
-- 3) After creating a user, copy its UUID from Authentication > Users and run:
--    insert into public.durga_member_accounts(auth_user_id, member_id, is_admin)
--    values ('AUTH-USER-UUID-HERE', 'DUR@900', true);
--    For normal members use false.
-- 4) Create the admin account mapping first. Sign in as admin once to upload
--    the starter data. Then create the remaining member accounts.
