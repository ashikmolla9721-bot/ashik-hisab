# আশিক হিসাব (Ashik Hisab)

**স্মার্ট ক্যালকুলেটর ও বাকির খাতা** — দোকানদারদের জন্য সম্পূর্ণ বাংলা হিসাব-নিকাশ অ্যাপ।

Flutter দিয়ে তৈরি, Android APK হিসেবে বিল্ড করার জন্য প্রস্তুত।

---

## ফিচার

**১. ক্যালকুলেটর** — ইংরেজি সংখ্যা ও চিহ্ন (+, −, ×, ÷, =, C, ⌫) দিয়ে সাধারণ হিসাব। প্রতিটি "=" চাপার সাথে সাথে হিসাবটি তারিখ ও নির্দিষ্ট সময়সহ **হিস্ট্রি**-তে স্বয়ংক্রিয়ভাবে জমা হয়। ফলাফল সরাসরি **বাকির খাতায়** পাঠানো যায় ("খাতায় পাঠান" বাটন)।

**২. বাকির খাতা** — কাস্টমারের নাম, ফোন, ঠিকানা দিয়ে প্রোফাইল তৈরি/এডিট। প্রতিটি কাস্টমারের জন্য **জমা** (নগদ গ্রহণ) ও **বাকি** (ধারে প্রদান) লেনদেন। রিয়েল-টাইমে দেখা যায় মোট জমা, মোট বাকি ও নিট ব্যালেন্স। ড্যাশবোর্ডে দেখা যায় **মোট বাজার বাকি / পাওনা**।

**৩. নোটপ্যাড** — বাংলায় নোট লেখা, এডিট ও ডিলিট। প্রতিটি নোটের তৈরি ও সম্পাদনার তারিখ-সময় স্বয়ংক্রিয়ভাবে সংরক্ষিত হয়।

**৪. হিস্ট্রি** — দিন-প্রতি-দিন গ্রুপ করা হিসাবের তালিকা। "হিস্ট্রি মুছে ফেলুন" দিয়ে এক ক্লিকে সব মুছে ফেলা যায়।

**৫. সেটিংস** — ডার্ক মোড, হিস্ট্রি/সব ডাটা মোছার অপশন, অ্যাপ তথ্য ও ব্র্যান্ডিং।

সব ডাটা ফোনেই (SQLite) থাকে — ইন্টারনেট লাগে না, কোনো তথ্য বাইরে যায় না।

---

## APK বানানোর পদ্ধতি ১ — নিজের উইন্ডোজ পিসিতে (সরাসরি APK ফাইল)

প্রয়োজন: Windows 10/11, ~৮ জিবি খালি জায়গা, ইন্টারনেট।

**ধাপ ১ — Flutter ইনস্টল করুন**

https://docs.flutter.dev/get-started/install/windows থেকে Flutter SDK নামান, যেমন `C:\flutter` ফোল্ডারে এক্সট্রাক্ট করুন, তারপর `C:\flutter\bin` কে PATH-এ যোগ করুন।

**ধাপ ২ — যাচাই করুন**

```
flutter doctor
```

Android toolchain-এ সব ঠিক থাকলে (✓) এগিয়ে যান।

**ধাপ ৩ — প্রজেক্ট ফোল্ডারে যান**

```
cd ashik_hisab
```

**ধাপ ৪ — Android প্ল্যাটফর্ম ফাইল তৈরি করুন**

```
flutter create --org com.ashik --project-name ashik_hisab --platforms android .
```

> এই কমান্ড `android/` ফোল্ডার বানাবে। এরপর জিপে দেওয়া `android/app/src/main/AndroidManifest.xml` ফাইলটি আবার কপি করে বসিয়ে দিন — এতে লঞ্চারে অ্যাপের নাম বাংলায় "আশিক হিসাব" দেখাবে।

**ধাপ ৫ — ডিপেন্ডেন্সি নামান**

```
flutter pub get
```

**ধাপ ৬ — APK বিল্ড করুন**

```
flutter build apk --release
```

**APK কোথায় পাবেন:**

```
build\app\outputs\flutter-apk\app-release.apk
```

এই ফাইলটি ফোনে কপি করুন (USB / ব্লুটুথ / হোয়াটসঅ্যাপ), ফোনে ইনস্টল করুন। ইনস্টলের সময় "Unknown sources" অনুমতি চাইলে অনুমতি দিন। চাইলে ফাইলের নাম বদলে `Ashik-Hisab.apk` রাখতে পারেন।

---

## APK বানানোর পদ্ধতি ২ — Codemagic (কিছু ইনস্টল না করে ক্লাউডে বিল্ড, ডাউনলোডেবল APK লিংক)

১. এই ফোল্ডারটি GitHub-এ পুশ করুন (private রেপো চলবে)।
২. https://codemagic.io এ ফ্রি অ্যাকাউন্ট খুলুন, GitHub কানেক্ট করুন।
৩. "Add application" → Flutter সিলেক্ট করুন।
৪. Workflow-এ বিল্ড স্টেপ দিন:
   - `flutter pub get`
   - `flutter build apk --release`
৫. Build চালু করুন। শেষ হলে **Artifacts** থেকে `app-release.apk` ডাউনলোড করুন — এটাই আপনার সরাসরি ইনস্টলযোগ্য APK।

---

## প্রজেক্ট স্ট্রাকচার

```
ashik_hisab/
├── pubspec.yaml
├── analysis_options.yaml
├── android/app/src/main/AndroidManifest.xml   (label = আশিক হিসাব)
├── README.md
└── lib/
    ├── main.dart                  (অ্যাপ এন্ট্রি, থিম, Provider)
    ├── db/db_helper.dart          (SQLite: calc_history, customers, transactions, notes)
    ├── providers/app_state.dart   (ডার্ক মোড + ট্যাবের মধ্যে পরিবর্তনের নোটিফিকেশন)
    ├── utils/helpers.dart         (বাংলা সংখ্যা, টাকা ও তারিখ ফরম্যাট)
    ├── utils/calc_engine.dart     (+ − × ÷ গণনার ইঞ্জিন, প্রায়োরিটি সহ)
    └── screens/
        ├── splash_screen.dart     (আশিক হিসাব ব্র্যান্ডিং)
        ├── home_screen.dart       (৫ ট্যাব: ক্যালকুলেটর | বাকির খাতা | নোটপ্যাড | হিস্ট্রি | সেটিংস)
        ├── calculator_screen.dart
        ├── history_screen.dart
        ├── ledger_screen.dart
        ├── add_customer_screen.dart
        ├── customer_detail_screen.dart
        ├── notepad_screen.dart
        ├── note_edit_screen.dart
        └── settings_screen.dart
```

## ডাটাবেজ স্কিমা (SQLite — `ashik_hisab.db`)

| টেবিল | কলাম |
|---|---|
| calc_history | id, expression, result, created_at |
| customers | id, name, phone, address, created_at |
| transactions | id, customer_id, is_jama (1=জমা, 0=বাকি), amount, note, created_at |
| notes | id, title, body, created_at, updated_at |

## ডিপেন্ডেন্সি

`sqflite`, `path`, `provider`, `intl`, `shared_preferences` — বিস্তারিত `pubspec.yaml`-এ।

## নোট

- ক্যালকুলেটর অংশের numeral ও চিহ্ন ইংরেজিতে (সর্বজনীন ব্যবহারের জন্য), বাকি সব UI ১০০% বাংলায়।
- প্রথমে `flutter create` চালিয়ে তারপর জিপের `AndroidManifest.xml` বসিয়ে দিলে বাংলা অ্যাপ নাম নিশ্চিত হবে।
- টেস্ট ডিভাইসে ইনস্টল করে দেখুন; কোনো বাগ পেলে জানান, ঠিক করে দেবো।
