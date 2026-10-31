# Security

- Browser uses only the Supabase publishable/anon key.
- Supabase RLS is enabled on both tables.
- Authenticated members can read the shared state; only accounts mapped as admins can insert/update it.
- Member/admin authority for database writes is checked server-side through `durga_member_accounts`, not the client-side UI flag.
- Do not disable RLS or expose a service_role/secret key.
- The shared JSON state is readable by all authenticated members. Do not store secrets or highly sensitive data in it.
- The starter data and client bundle are public on GitHub Pages. Never store passwords in `data.json` or source code.
