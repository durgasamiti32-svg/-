DURGA SAMITI WEBSITE - নতুন সংস্করণ
===================================

নতুন সুবিধা
-----------
1. সদস্যের নাম + ১০ সংখ্যার Member ID দিয়ে লগইন।
2. সদস্যের প্রোফাইল: ছবি, ফোন, ঠিকানা, জন্মতারিখ, পদ, চাঁদা ও Member ID।
3. Members পেজে সক্রিয়/নিষ্ক্রিয় সদস্য দেখা এবং প্রোফাইল খোলা।
4. Bills ও চাঁদা: সাল অনুযায়ী সদস্য, খরচ, অন্যান্য দায়িত্ব এবং পাড়ার চাঁদা।
5. প্রতি বছরের হিসাব আলাদা JSON ডেটা হিসেবে থাকে; পুরোনো বছরের হিসাব অক্ষত থাকে।
6. মোট জমা, মোট খরচ ও অবশিষ্ট ব্যালান্স।
7. নির্বাচিত বছরের সব রেকর্ড CSV (Excel-এ খোলা যায়) ডাউনলোড।
8. Settings থেকে Gallery-তে সরাসরি ছবির URL যোগ/ডিলিট।
9. Settings থেকে শুধু ছবির URL দিয়ে ওয়েবসাইটের লোগো পরিবর্তন।
10. সকল সদস্যের জন্য একটি Realtime Group Chat।
11. Settings Password দিয়ে সব তথ্য সম্পাদনা।

সেটআপ
-----
A. ZIP extract করে ফোল্ডারের ফাইল GitHub Pages repository-তে আপলোড করুন।
B. config.js ফাইল খুলুন।
   SUPABASE_URL-এ আপনার Project URL বসান।
   SUPABASE_ANON_KEY-এ Publishable/anon key বসান।
   service_role key কখনো ব্যবহার করবেন না।
C. Supabase Dashboard > SQL Editor > New Query খুলুন।
D. এই ফোল্ডারের supabase.sql-এর সম্পূর্ণ কোড পেস্ট করে RUN করুন।
E. GitHub Pages সাইট খুলে পরীক্ষা করুন।

Settings Password
-----------------
আগের ডাটাবেসে Settings Password আগে থেকেই থাকলে সেটি অপরিবর্তিত থাকবে।
নতুন ডাটাবেসে প্রথমবার SQL চালালে প্রাথমিক পাসওয়ার্ড: AK@2026#£

ছবি ও লোগো
----------
Member profile photo, Gallery photo এবং Logo-তে সরাসরি https:// image URL ব্যবহার করুন।
URL-টি সরাসরি ছবির ফাইল খুলতে হবে। Google Drive share URL অনেক সময় সরাসরি ছবি দেখায় না।
এই সংস্করণে Gallery-তে URL দিয়ে ছবি যোগ করা হয়; ফাইল আপলোড/Storage যুক্ত করা হয়নি।

গুরুত্বপূর্ণ নিরাপত্তা তথ্য
-------------------------
Member Name + ID হলো সহজ লগইন ব্যবস্থা, শক্ত পরিচয় যাচাই নয়। কারও Member ID জেনে গেলে সে ঐ সদস্যের নামে ঢোকার চেষ্টা করতে পারে।
Settings Password যার জানা থাকবে, সে সব তথ্য পরিবর্তন করতে পারবে। পাসওয়ার্ড কাউকে অযথা দেবেন না।
Chat-এও Member ID + নামের মিল পরীক্ষা হয়, কিন্তু এটি শক্ত authentication নয়।

ফাইল
----
index.html       - ওয়েবসাইটের কাঠামো
style.css        - ডিজাইন ও মোবাইল responsive style
config.js        - Supabase URL এবং anon key
app.js           - ওয়েবসাইটের কার্যপ্রণালী
supabase.sql     - Supabase database upgrade SQL
README_BN.txt    - বাংলা নির্দেশিকা
