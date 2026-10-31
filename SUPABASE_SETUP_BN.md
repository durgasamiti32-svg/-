# Durga Samiti Website — Supabase Database Setup (বাংলা)

এই ZIP-এ মূল HTML/CSS ডিজাইন অপরিবর্তিত রাখা হয়েছে। এখন Supabase Auth দিয়ে Member ID + Password লগইন, একটি shared database record, RLS এবং Realtime sync যুক্ত আছে।

## ১) Supabase Project Key বসাও
1. Supabase Dashboard খুলে তোমার Project নির্বাচন করো।
2. Project Settings → API (বা API Keys) → Publishable key কপি করো। পুরোনো Project হলে `anon public` key ব্যবহার করা যায়।
3. ZIP-এর `config.js` ফাইল খুলে `PASTE_YOUR_SUPABASE_PUBLISHABLE_KEY_HERE`-এর জায়গায় ওই key বসাও।
4. URL আগে থেকেই এই Project-এর URL হিসেবে রাখা হয়েছে। তোমার Project আলাদা হলে URL-টিও বদলাবে।
5. `service_role` বা Secret key কখনো `config.js`, HTML, GitHub বা ZIP-এ বসাবে না।

## ২) Database SQL চালাও
1. Supabase → SQL Editor → New query খোলো।
2. `supabase-setup.sql` (অথবা একই কোড থাকা `seed.sql`) পুরোটা কপি করে Run করো।
3. এখানে RLS চালু থাকবে। **RLS বন্ধ করবে না।**

## ৩) প্রথম Admin account তৈরি করো
এই অ্যাপের Login-এ Member ID + Password থাকবে। Supabase Auth-এ প্রতিটি সদস্যের আলাদা user account তৈরি করতে হবে।

1. Authentication → Providers → Email খুলে Email provider Enabled রাখো।
2. Email confirmations বন্ধ করো (কারণ এই প্রকল্পে synthetic login email ব্যবহৃত হচ্ছে; আসল ইমেল পাঠানো হয় না)।
3. Authentication → Users → Add user → Create new user।
4. Admin-এর জন্য Email হবে: `member-ZHVyQDkwMA@durga-samiti.invalid`
   - এটি `DUR@900` Member ID-এর জন্য।
   - Password হিসেবে Admin-এর জন্য নতুন শক্তিশালী password দাও।
5. তৈরি হওয়া User-এর UUID কপি করো।
6. SQL Editor-এ চালাও (UUID-টি বদলে):
   ```sql
   insert into public.durga_member_accounts(auth_user_id, member_id, is_admin)
   values ('PASTE-ADMIN-AUTH-UUID', 'DUR@900', true);
   ```
7. GitHub Pages-এ সাইট খোলো। নাম `আকাশ কর্মকার`, Member ID `DUR@900`, এবং Supabase Auth-এ সেট করা Password দিয়ে লগইন করো।
8. প্রথমবার shared database খালি থাকলে Admin-এর ব্রাউজারে থাকা starter data database-এ আপলোড হবে।

## ৪) অন্য Member account তৈরি করো
প্রত্যেক সদস্যের জন্য:
1. Authentication → Users → Add user-এ একটি user তৈরি করো।
2. Email alias তৈরি করার নিয়ম: Member ID ছোট হাতের অক্ষরে UTF-8 Base64URL encode করে `member-` আগে এবং `@durga-samiti.invalid` পরে বসাও।
   - উদাহরণ `DUR002` → `member-ZHVyMDAy@durga-samiti.invalid`
   - উদাহরণ `DUR003` → `member-ZHVyMDAz@durga-samiti.invalid`
3. একটি password নির্ধারণ করো এবং User UUID কপি করো।
4. SQL Editor-এ চালাও:
   ```sql
   insert into public.durga_member_accounts(auth_user_id, member_id, is_admin)
   values ('PASTE-MEMBER-AUTH-UUID', 'DUR002', false);
   ```
5. সদস্য লগইন করবে তার নাম, Member ID এবং ওই password দিয়ে।

## ৫) GitHub Pages-এ Publish
1. ZIP extract করো।
2. `index.html`, `config.js`, `supabase-sync.js`, `data.json`, ছবি এবং বাকি ফাইল একই repository folder-এ রাখো।
3. `config.js`-এ publishable/anon key বসিয়ে GitHub-এ commit ও push করো।
4. Repository → Settings → Pages → Deploy from branch নির্বাচন করো।
5. `index.html` যে folder-এ আছে সেই folder-টাই Pages source করো।

## কীভাবে Sync হবে
- Admin নতুন Member, আয়-ব্যয়, Notice/Photo/Gallery বা অন্য supported website data save করলে shared JSON state-এ যাবে।
- লগইন করা সব সদস্য database থেকে একই তথ্য পড়বে।
- Realtime subscription চালু থাকলে Admin-এর পরিবর্তন অন্য সদস্যের খোলা পেজেও আপডেট হবে।
- Members read-only। Browser থেকে Admin সেজে database overwrite করা যাবে না; Admin write permission Supabase-এর `durga_member_accounts.is_admin` থেকে যাচাই হয়।
- এই starter-এর chat/member-side write action আলাদা secure table-এ migrate করা হয়নি; তাই member-generated chat message বা member-side edit cloud sync নাও করতে পারে। Admin-created shared website data হলো synced scope।

## নিরাপত্তা ও সীমাবদ্ধতা
- `data.json` ও frontend source জনসাধারণের কাছে পড়া যায়; তাই সেখানে ব্যক্তিগত password রাখা যাবে না। এই সংস্করণে embedded/demo password সরানো হয়েছে। Auth password শুধু Supabase Auth-এ থাকবে।
- Member data-তে ঠিকানা, ফোন, ছবি ইত্যাদি থাকলে মনে রেখো: shared JSON row-তে সেগুলো সব signed-in member পড়তে পারে। সংবেদনশীল তথ্যের জন্য আলাদা table ও column-level policy দরকার।
- Supabase free plan-এর সীমা/ব্যবহার অনুযায়ী storage ও realtime quota প্রযোজ্য।
- পুরোনো LocalStorage-এ থাকা তথ্য প্রথম Admin login-এ seed হিসেবে ব্যবহৃত হতে পারে। পুরোনো ডেটা ভুল হলে আগে Admin-এর browser-এ সঠিক data import করে তারপর প্রথমবার sync করো।
