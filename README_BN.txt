DURGA SAMITI WEBSITE — বাংলা সেটআপ

এই ZIP-এ ৫টি ফাইল আছে:
index.html = ওয়েবসাইট
style.css = ডিজাইন
app.js = Login, সদস্য, নোটিশ, হিসাব ও Realtime
config.js = Supabase URL ও Publishable/anon key
supabase.sql = Database তৈরির SQL

১) Supabase Dashboard > SQL Editor > New Query খুলুন। supabase.sql-এর সব কোড পেস্ট করে RUN করুন। Success দেখালে SQL সফল।

২) Supabase > Project Settings > API খুলুন। Project URL ও Publishable key (বা anon public key) কপি করুন। config.js-এ PASTE_PROJECT_URL_HERE এবং PASTE_PUBLISHABLE_OR_ANON_KEY_HERE-এর জায়গায় বসান। service_role/secret key কখনো বসাবেন না।

৩) ZIP Extract করে পাঁচটি ফাইল GitHub repository-র root folder-এ Upload করুন। GitHub Settings > Pages > Deploy from branch > main > /(root) > Save করুন।

প্রথমে ১২ জনের সদস্য রেকর্ড তৈরি হবে। শেষের ৯ জনের নাম অস্থায়ী; Settings > সদস্য থেকে Edit করতে পারবেন। Settings Password: AK@2026#£

Settings থেকে সদস্যের নাম/ID, Notice, আয় ও ব্যয় বদলানো যায়। Save করলে Supabase-এ সেভ হবে এবং অন্য সদস্যদের পেজে Realtime update আসবে।

Password বদলাতে SQL Editor-এ চালান:
update public.durga_settings_secret set password_hash=extensions.crypt('YOUR_NEW_PASSWORD',extensions.gen_salt('bf')) where id=1;

নিরাপত্তা: Member Name + ID কেবল সহজ প্রবেশ পদ্ধতি, প্রকৃত পরিচয় যাচাই নয়। যার কাছে কারও ID আছে সে তার নামে ঢোকার চেষ্টা করতে পারে। Settings Password যাদের জানা থাকবে তারা সব তথ্য পরিবর্তন করতে পারবে। এখানে কোনো Admin role নেই। এই ZIP একটি নতুন কম-ফাইলের সংস্করণ; আগের ওয়েবসাইটের অন্য ফিচার এতে অন্তর্ভুক্ত নয়।
