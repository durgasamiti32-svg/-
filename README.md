# Durga Samiti Website

Static GitHub Pages website with Supabase Auth, RLS-protected shared state and Realtime updates.

Start here: `SUPABASE_SETUP_BN.md`

Required setup:
1. Put the Supabase publishable/anon key in `config.js`.
2. Run `supabase-setup.sql` in Supabase SQL Editor.
3. Create Supabase Auth users and map them in `durga_member_accounts` as described in the Bengali guide.
4. Deploy the folder to GitHub Pages.

Never put a Supabase service_role/secret key in frontend files.
