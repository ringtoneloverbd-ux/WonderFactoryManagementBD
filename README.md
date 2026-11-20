# Wonder Factory Management — Android APK starter

এই Flutter প্রজেক্টটি মোবাইলের Chrome দিয়েও GitHub-এ আপলোড করে GitHub Actions-এর ক্লাউড কম্পিউটারে APK বানানোর জন্য প্রস্তুত করা হয়েছে। নিজের কম্পিউটারে Flutter/Android Studio ইনস্টল করা লাগবে না।

## এই সংস্করণে যা আছে
- বাংলা ড্যাশবোর্ড
- উৎপাদনের তারিখ, পণ্য ও কার্টন সংখ্যা দিয়ে এন্ট্রি
- উৎপাদনের ইতিহাস; কার্টন সংখ্যা সম্পাদনা ও রেকর্ড মুছে ফেলা
- মাসভিত্তিক ও পণ্যভিত্তিক রিপোর্ট
- পণ্যের তালিকা এবং নতুন পণ্য যোগ
- Bombay Fly (চরকি) আলাদা হিসাব; মূল কার্টন মোটে যোগ হয় না
- SQLite-এ এই ফোনে লোকাল ডেটা সংরক্ষণ

পণ্যের নামের বানান/তালিকা পরে অ্যাপের Product অংশ থেকে পরিবর্তন করা যাবে। প্রাথমিক তালিকায় “Kids Tools Set” রাখা হয়েছে।

## গুরুত্বপূর্ণ সীমাবদ্ধতা
এই সংস্করণে তথ্য শুধু যে ফোনে এন্ট্রি করা হবে সেই ফোনেই থাকবে। অন্য ফোনে একই তথ্য দেখা, অনলাইন সিঙ্ক, লগইন/অ্যাডমিন-কর্মচারী অনুমতি, ক্লাউড ব্যাকআপ এখনো যুক্ত হয়নি। এগুলো যোগ ও পরীক্ষা না করে একাধিক ফোনে ব্যবহারের জন্য এটিকে চূড়ান্ত সিস্টেম ভাববেন না।

## শুধু Android ফোন দিয়ে APK বানানোর পদ্ধতি
1. Chrome-এ https://github.com খুলে অ্যাকাউন্টে সাইন ইন/নতুন অ্যাকাউন্ট তৈরি করুন।
2. `New repository` চাপুন। নাম দিন `wonder-factory-management`, visibility `Private` রাখুন, তারপর `Create repository` চাপুন।
3. ফোনে ZIP ফাইলটি ডাউনলোড করে Extract/Unzip করুন। ZIP-এর ভেতরের `WonderFactoryManagement` ফোল্ডারের ফাইলগুলো (বিশেষ করে `.github` ফোল্ডারসহ) রিপোজিটরির মূল জায়গায় আপলোড করুন। `Add file` → `Upload files` ব্যবহার করুন।
4. আপলোড শেষে `Commit changes` চাপুন।
5. রিপোজিটরির `Actions` ট্যাবে যান। `Build Wonder Factory APK` workflow চলবে। না চললে workflow খুলে `Run workflow` চাপুন।
6. সবুজ টিক এলে workflow run খুলে নিচে `Artifacts` থেকে `WonderFactoryManagement-APK` ডাউনলোড করুন। ZIP-টি Extract করলে `app-release.apk` পাবেন।
7. APK ফোনে খুলে Android-এর নির্দেশনা অনুযায়ী এই উৎস থেকে ইনস্টল করার অনুমতি দিন। শুধু নিজের তৈরি APK ইনস্টল করুন।

### GitHub-এ আপলোডের সময় খেয়াল রাখুন
- `README.md`, `pubspec.yaml`, `lib` এবং `.github/workflows/build-apk.yml` যেন রিপোজিটরির root-এ থাকে।
- `.github` একটি hidden folder হতে পারে। আপলোডে এটি বাদ পড়লে Actions workflow চলবে না।
- কোনো Firebase secret, password বা ব্যক্তিগত key রিপোজিটরিতে দেবেন না।

## Build workflow
`.github/workflows/build-apk.yml` GitHub-এর ক্লাউড runner-এ Android project files তৈরি করে release APK বানায় এবং APK-কে artifact হিসেবে সংযুক্ত করে। এই APK বর্তমানে debug-signing configuration দিয়ে তৈরি হবে; Play Store প্রকাশের আগে নিজস্ব release keystore দিয়ে আলাদা signing করতে হবে।
