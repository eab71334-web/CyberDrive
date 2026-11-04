# CyberDrive 🚙⚡
تطبيق تحكم بسيارة عن طريق Bluetooth LE (أندرويد + آيفون) باستخدام Flutter.

## الاستخدام
1. ارفع المشروع على GitHub (فرع `main`).
2. تبويب **Actions** ← شغّل `Build Android APK` و `Build iOS IPA (unsigned)`.
3. حمّل الملفات من **Artifacts**.
4. الآيفون: ملف IPA غير موقّع، ثبّته بـ Sideloadly أو AltStore أو TrollStore.

## بروتوكول الأوامر (نص ASCII)
`F` أمام · `B` خلف · `L` يسار · `R` يمين · `S` وقوف · `1-9` سرعة · `W/w` أضواء · `V` منبه

## مهم
- آيفون يدعم **BLE فقط**. وحدات HC-05 / HC-06 (Classic) لا تعمل معه. استخدم HM-10 أو ESP32 BLE.
- الإعداد الافتراضي: Service `FFE0` و Characteristic `FFE1` (عدّلهما في `lib/main.dart`).
- مثال كود السيارة في `arduino/car.ino`.
