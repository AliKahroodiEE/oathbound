<div dir="rtl">

# استقرار Wyrd برای کاربران واقعی

[English](deployment.md)

این فهرست کارهای صاحب پروژه است برای اجرای Wyrd برای کاربران واقعی با هزینه‌ی **صفر دلار در ماه**.
مراحل را یک بار به ترتیب انجام بده؛ از آن به بعد هر push به شاخه‌ی `main` نسخه‌ی وب را دوباره منتشر
می‌کند و هر تگ `v*` یک نسخه‌ی تازه‌ی اندروید می‌سازد.

| بخش | کجا اجرا می‌شود | چطور منتشر می‌شود |
| --- | --- | --- |
| برنامه‌ی وب (همان برنامه‌ی آیفون) | Cloudflare Pages، نشانی `https://wyrd-app.pages.dev` | [`deploy-web.yml`](../.github/workflows/deploy-web.yml) با هر push به `main` |
| بک‌اند (پایگاه داده، ورود، Edge Functions) | پلن رایگان Supabase | گردش‌کار استقرار بک‌اند ([backend/README.md](../backend/README.md)) |
| برنامه‌ی اندروید | فایل APK امضاشده در GitHub Releases | [`release-android.yml`](../.github/workflows/release-android.yml) با هر تگ `v*` |
| ایمیل‌های ورود | Brevo (یا Gmail) از راه SMTP | SMTP سفارشی Supabase |
| اعلان‌ها (push) | Firebase Cloud Messaging | تابع `notify` در Edge Functions |

نشانی عمومی سایت فقط در **یک** جا تعریف می‌شود: متغیر مخزن گیت‌هاب به نام `WYRD_SITE_URL`. هر
چیزی که به این نشانی نیاز دارد (ساخت نسخه‌ی وب، فایل APK و تنظیمات بازگشت Supabase) آن را از همین
متغیر می‌خواند؛ پس رفتن به دامنه‌ی شخصی در آینده کار کوتاهی است ([دامنه‌ی شخصی در آینده](#custom-domain)).

## سقف پلن‌های رایگان

| سرویس | سهمیه‌ی رایگان | حواست باشد |
| --- | --- | --- |
| Supabase | ۵۰۰ مگابایت پایگاه داده، ۵ گیگابایت ترافیک خروجی در ماه، ۵۰٬۰۰۰ کاربر فعال ماهانه، ۱ گیگابایت فضای فایل، ۵۰۰٬۰۰۰ اجرای Edge Function در ماه | پروژه **بعد از ۷ روز بدون فعالیت پایگاه داده متوقف می‌شود** (از داشبورد دوباره راهش بینداز). **پشتیبان‌گیری خودکار ندارد**؛ مرحله‌ی ۷ برای همین است. |
| Cloudflare Pages | درخواست‌ها و پهنای باند فایل‌های ایستا نامحدود | حداکثر ۲۰٬۰۰۰ فایل در هر استقرار و ۲۵ مبی‌بایت برای هر فایل (خروجی وب خیلی کمتر از این است). |
| Brevo | ۳۰۰ ایمیل در روز | نشانی فرستنده باید تأیید شود؛ بدون دامنه‌ی شخصی بعضی ایمیل‌ها به هرزنامه می‌روند. |
| Gmail (جایگزین) | حدود ۵۰۰ ایمیل در روز | تأیید دومرحله‌ای و یک app password لازم است. |
| Resend (بعداً، با دامنه‌ی شخصی) | ۳٬۰۰۰ ایمیل در ماه، ۱۰۰ در روز | باید رکوردهای DNS دامنه‌ات را تنظیم کنی. |
| Firebase Cloud Messaging | رایگان | — |
| GitHub | Actions برای مخزن عمومی رایگان است، Releases رایگان است | مخزن خصوصی ماهانه ۲٬۰۰۰ دقیقه Actions دارد. |

## پیش‌نیازها

- حساب گیت‌هاب با دسترسی مدیر روی این مخزن و [GitHub CLI](https://cli.github.com) که با
  `gh auth login` وارد شده باشد.
- یک JDK برای ابزار `keytool` (همراه Android Studio نصب می‌شود) تا کلید امضای اندروید ساخته شود.
- ابزار [age](https://github.com/FiloSottile/age) برای پشتیبان‌های رمزشده (`brew install age`،
  `sudo apt install age` یا `winget install FiloSottile.age`).
- یک مدیر رمز عبور؛ بعضی از مقدارهای زیر فقط یک بار نشان داده می‌شوند.

مقدارهای مرحله‌های ۱ تا ۷ را جمع کن و بعد `tool/setup_production.sh` را اجرا کن (مرحله‌ی ۹) تا همه
را در گیت‌هاب ذخیره کند. نام‌هایی که به شکل `code` آمده‌اند، نام secret (خصوصی) یا variable (تنظیم
عمومی برنامه) در گیت‌هاب هستند و اسکریپت تک‌تک‌شان را می‌پرسد.

## ۱. پروژه‌ی Supabase

1. پروژه را در <https://supabase.com/dashboard/new> بساز: نام `wyrd`، یک **رمز پایگاه داده‌ی** بلند و
   تصادفی (نگهش دار: `SUPABASE_DB_PASSWORD`) و **نزدیک‌ترین منطقه به بیشتر کاربرانت** (برای اروپا و
   خاورمیانه، فرانکفورت انتخاب خوبی است). پلن رایگان دو پروژه‌ی فعال را اجازه می‌دهد.
2. **شناسه‌ی پروژه (ref)** همان بخش آخر نشانی داشبورد است، یعنی
   `https://supabase.com/dashboard/project/<ref>`: این می‌شود `SUPABASE_PROJECT_ID`. **نشانی پروژه**
   `https://<ref>.supabase.co` است: `SUPABASE_URL`.
3. کلیدهای API در <https://supabase.com/dashboard/project/_/settings/api-keys>: **کلید publishable**
   (`sb_publishable_…`) را کپی کن: `SUPABASE_PUBLISHABLE_KEY`. پروژه‌های تازه دیگر کلیدهای قدیمی
   `anon` و `service_role` ندارند؛ کلیدهای `sb_secret_…` هیچ‌وقت از Supabase بیرون نمی‌روند (Edge
   Functions خودکار آن‌ها را می‌گیرند).
4. توکن دسترسی شخصی برای گردش‌کار استقرار، در <https://supabase.com/dashboard/account/tokens>:
   **Generate new token**، که می‌شود `SUPABASE_ACCESS_TOKEN`.
5. اگر رمز پایگاه داده را گم کردی، در <https://supabase.com/dashboard/project/_/database/settings>
   عوضش کن.

لازم نیست چیز دیگری را در داشبورد تنظیم کنی: روش‌های ورود، نشانی‌های بازگشت، SMTP و قالب ایمیل‌ها
از `backend/supabase/config.toml` می‌آیند و استقرار بک‌اند آن‌ها را اعمال می‌کند. در پروژه‌های تازه
جدول‌ها خودکار در Data API در دسترس نیستند؛ migrationها دقیقاً همان دسترسی‌هایی را می‌دهند که برنامه
لازم دارد.

## ۲. حساب Cloudflare

1. در <https://dash.cloudflare.com/sign-up> ثبت‌نام کن (پلن رایگان، کارت بانکی لازم نیست).
2. **Account ID**: صفحه‌ی <https://dash.cloudflare.com/?to=/:account/workers-and-pages> را باز کن و
   Account ID را از ستون کناری کپی کن: `CLOUDFLARE_ACCOUNT_ID`.
3. **توکن API**: در <https://dash.cloudflare.com/profile/api-tokens> روی **Create Token** و بعد
   **Create Custom Token** بزن. دسترسی: *Account* · *Cloudflare Pages* · *Edit*. منابع حساب:
   *Include* · حساب خودت. نگهش دار: `CLOUDFLARE_API_TOKEN`.
4. نام پروژه‌ی Pages: `wyrd-app` (نام `wyrd` گرفته شده): `CF_PAGES_PROJECT`. لازم نیست خودت
   بسازی‌اش؛ اولین استقرار آن را می‌سازد.

## ۳. فرستنده‌ی ایمیل

کدهای ورود، تأیید ثبت‌نام و بازیابی رمز همه کدهای ۶ رقمی‌اند که با ایمیل فرستاده می‌شوند. فرستنده‌ی
داخلی Supabase فقط به اعضای تیم خودت در Supabase ایمیل می‌دهد (ساعتی ۲ تا)، پس برای کاربران واقعی یک
حساب SMTP جدا لازم است. یکی را انتخاب کن:

**Brevo (پیشنهاد فعلی).** رایگان، روزی ۳۰۰ ایمیل، بدون نیاز به دامنه.

1. در <https://www.brevo.com> ثبت‌نام کن.
2. نشانی فرستنده (صندوقی که مال خودت است) را اضافه و تأیید کن:
   <https://app.brevo.com/senders/list>. این می‌شود `SMTP_ADMIN_EMAIL`.
3. تنظیمات SMTP در <https://app.brevo.com/settings/keys/smtp>: سرور `smtp-relay.brevo.com`
   (`SMTP_HOST`)، درگاه `587` (`SMTP_PORT`)، **login** که همان‌جا نشان داده می‌شود و شبیه
   `…@smtp-brevo.com` است (`SMTP_USER`) و یک **SMTP key** تازه (`SMTP_PASS`).

**Gmail.** از حساب گوگل خودت استفاده می‌کند؛ حدود ۵۰۰ ایمیل در روز.

1. تأیید دومرحله‌ای را روشن کن: <https://myaccount.google.com/signinoptions/twosv>.
2. یک app password به نام `Wyrd` بساز: <https://myaccount.google.com/apppasswords> (۱۶ حرف،
   `SMTP_PASS`).
3. سرور `smtp.gmail.com`، درگاه `587`، نام کاربری و فرستنده همان نشانی Gmail توست.

نام فرستنده (`SMTP_SENDER_NAME`) همان `Wyrd` است. تا وقتی دامنه‌ی شخصی نداری، از آزمایش‌کننده‌ها
بخواه بار اول پوشه‌ی هرزنامه را هم نگاه کنند. وقتی دامنه گرفتی، به Resend برو
([دامنه‌ی شخصی در آینده](#custom-domain)).

## ۴. ورود با گوگل

در کنسول Google Cloud، با حسابی که باید مالک برنامه باشد:

1. یک پروژه بساز: <https://console.cloud.google.com/projectcreate> (در مرحله‌ی ۶ می‌توانی همین را
   برای Firebase هم به کار ببری).
2. **Branding** (صفحه‌ی رضایت) در <https://console.cloud.google.com/auth/branding>: نام برنامه
   `Wyrd`، ایمیل پشتیبانی، صفحه‌ی اصلی `WYRD_SITE_URL` و دامنه‌های مجاز `wyrd-app.pages.dev` (بعداً
   دامنه‌ی خودت) و `<ref>.supabase.co`. در **Audience**
   (<https://console.cloud.google.com/auth/audience>) گزینه‌ی *External* را بزن و بعد
   **Publish app**. در **Data access** (<https://console.cloud.google.com/auth/scopes>) فقط
   `openid`، `…/auth/userinfo.email` و `…/auth/userinfo.profile`. این‌ها حساس نیستند، پس گوگل
   برنامه را بازبینی نمی‌کند.
3. **کلاینت وب**: در <https://console.cloud.google.com/auth/clients> روی **Create client** بزن و
   *Web application* را انتخاب کن:
   - Authorized JavaScript origins: `https://wyrd-app.pages.dev` (همان `WYRD_SITE_URL`).
   - Authorized redirect URIs: `https://<ref>.supabase.co/auth/v1/callback`.
   - **client ID** را (`GOOGLE_WEB_CLIENT_ID`) و **client secret** را (`GOOGLE_CLIENT_SECRET`) کپی کن.
4. **کلاینت اندروید**: **Create client** و بعد *Android*، با package name برابر `app.wyrd` و
   **SHA-1 کلید انتشار**. اسکریپت `tool/setup_production.sh` وقتی کلید را می‌سازد (مرحله‌ی ۸) این
   مقدار را چاپ می‌کند، پس می‌توانی بعد از مرحله‌ی ۹ به این‌جا برگردی. هیچ مقداری از این کلاینت به
   گیت‌هاب نمی‌رود؛ فقط باید وجود داشته باشد. برای ورود از نسخه‌های debug خودت، یک کلاینت اندروید دوم
   با SHA-1 کلید debug بساز.

<div dir="ltr">

```bash
keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android
```

</div>

## ۵. ورود با گیت‌هاب

1. یک OAuth app تازه بساز: <https://github.com/settings/applications/new> (یک *OAuth App*، نه
   GitHub App).
   - نام برنامه `Wyrd` و homepage URL برابر `WYRD_SITE_URL`.
   - Authorization callback URL: `https://<ref>.supabase.co/auth/v1/callback`.
2. روی **Generate a new client secret** بزن. client ID و secret را کپی کن.

گیت‌هاب اجازه نمی‌دهد نام secret یا variable با `GITHUB_` شروع شود، پس این‌ها با نام
`GH_OAUTH_CLIENT_ID` (variable) و `GH_OAUTH_CLIENT_SECRET` (secret) ذخیره می‌شوند. مقدار
`WYRD_AUTH_GITHUB=true` دکمه‌ی گیت‌هاب را در برنامه نشان می‌دهد. گوشی‌ها از راه
`app.wyrd://auth-callback` به برنامه برمی‌گردند و تنظیمات بک‌اند این بازگشت را مجاز می‌کند.

## ۶. Firebase (اعلان‌ها)

1. در <https://console.firebase.google.com> روی **Create a project** بزن (یا Firebase را به پروژه‌ی
   Google Cloud مرحله‌ی ۴ اضافه کن). Google Analytics لازم نیست.
2. **برنامه‌ی وب**: در Project settings بخش *Your apps* یک برنامه‌ی وب (`</>`) با نام `Wyrd` و بدون
   Hosting اضافه کن. از تنظیماتی که نشان می‌دهد: `apiKey` می‌شود `FIREBASE_API_KEY`، `appId` می‌شود
   `FIREBASE_APP_ID_WEB`، `messagingSenderId` می‌شود `FIREBASE_MESSAGING_SENDER_ID` و `projectId`
   می‌شود `FIREBASE_PROJECT_ID`.
3. **برنامه‌ی اندروید**: یک برنامه‌ی اندروید با package name برابر `app.wyrd` اضافه کن. App ID آن
   (`1:…:android:…`) می‌شود `FIREBASE_APP_ID_ANDROID`. برنامه هنگام ساخت از همین مقدارها تنظیم
   می‌شود؛ فایل `google-services.json` لازم نیست (و بیرون از git می‌ماند).
4. **کلید web push**: در <https://console.firebase.google.com/project/_/settings/cloudmessaging>
   بخش *Web configuration* روی **Generate key pair** بزن. کلید عمومی می‌شود `FIREBASE_VAPID_KEY`.
5. **کلید سرور** برای تابع `notify`: در
   <https://console.firebase.google.com/project/_/settings/serviceaccounts/adminsdk> روی
   **Generate new private key** بزن. فایل JSON دانلودشده را بیرون از مخزن نگه دار؛ اسکریپت آن را در
   `FCM_SERVICE_ACCOUNT` می‌ریزد و بعد می‌توانی پاکش کنی.

مقدارهای تنظیم وب Firebase ذاتاً عمومی‌اند؛ فقط کلید service account محرمانه است.

## ۷. پشتیبان‌گیری

پروژه‌های رایگان Supabase پشتیبان خودکار ندارند. پشتیبان‌ها برای یک کلید
[age](https://github.com/FiloSottile/age) رمز می‌شوند، پس هر جایی می‌شود نگهشان داشت و فقط خودت
می‌توانی بازشان کنی:

<div dir="ltr">

```bash
mkdir -p ~/.config/wyrd
age-keygen -o ~/.config/wyrd/wyrd-backup-key.txt   # prints "Public key: age1…"
```

</div>

- کلید عمومی (`age1…`) می‌شود `BACKUP_AGE_RECIPIENT` (یک variable؛ فقط می‌تواند رمز کند).
- فایل کلید تنها راه باز کردن پشتیبان‌هاست. یک نسخه از آن را در مدیر رمز عبور یا جای آفلاین دیگری
  نگه دار. هیچ‌وقت commitاش نکن و در گیت‌هاب نگذارش.
- برای خواندن یک پشتیبان:

<div dir="ltr">

```bash
age --decrypt -i ~/.config/wyrd/wyrd-backup-key.txt <file>.age > <file>
```

</div>

اسکریپت راه‌اندازی می‌تواند `age-keygen` را برایت اجرا کند.

## ۸. کلید امضای اندروید

فایل APK باید برای همیشه با یک کلید امضا شود: اندروید فقط وقتی به‌روزرسانی را روی برنامه‌ی نصب‌شده
می‌نشاند که امضاها یکی باشند. اسکریپت راه‌اندازی کلید را با `keytool` می‌سازد (RSA با طول ۴۰۹۶
بیت، معتبر برای ۲۷ سال)، SHA-1 آن را برای مرحله‌ی ۴ چاپ می‌کند و آن را با نام‌های
`ANDROID_KEYSTORE_BASE64`، `ANDROID_KEYSTORE_PASSWORD`، `ANDROID_KEY_ALIAS` و `ANDROID_KEY_PASSWORD`
در گیت‌هاب ذخیره می‌کند.

**از فایل keystore و رمزش نسخه‌ی پشتیبان بگیر.** اگر گم شوند، کاربران فقط بعد از حذف نسخه‌ی قبلی
می‌توانند نسخه‌ی تازه را نصب کنند و داده‌های محلی‌شان پاک می‌شود.

برای امضای نسخه‌ی انتشار روی کامپیوتر خودت، `app/android/key.properties.example` را به
`app/android/key.properties` کپی کن (در git نادیده گرفته می‌شود) و پرش کن. بدون آن، نسخه‌های انتشار
محلی با کلید debug امضا می‌شوند.

## ۹. ذخیره‌ی همه‌چیز در گیت‌هاب

از داخل مخزن:

<div dir="ltr">

```bash
gh auth login                    # once
tool/setup_production.sh         # or: tool/setup_production.sh --repo OWNER/REPO
```

</div>

اسکریپت گروه‌های بالا را یکی‌یکی می‌پرسد، اجازه می‌دهد هر کدام را رد کنی و هر وقت خواستی می‌شود
دوباره اجرایش کرد (Enter مقدار ذخیره‌شده را نگه می‌دارد). رمزها، توکن‌ها و کلیدها هنگام تایپ نمایش
داده نمی‌شوند و از راه stdin به `gh` می‌رسند. نتیجه را در
`https://github.com/OWNER/REPO/settings/secrets/actions` (زبانه‌های secrets و variables) ببین.

| نام | نوع | چه کسی استفاده می‌کند |
| --- | --- | --- |
| `SUPABASE_URL`، `SUPABASE_PUBLISHABLE_KEY` | variable | ساخت نسخه‌ی وب و اندروید |
| `SUPABASE_PROJECT_ID`، `SUPABASE_ACCESS_TOKEN`، `SUPABASE_DB_PASSWORD` | secret | استقرار بک‌اند |
| `WYRD_SITE_URL` | variable | هر چیزی که نشانی عمومی را لازم دارد |
| `CLOUDFLARE_API_TOKEN`، `CLOUDFLARE_ACCOUNT_ID` | secret | استقرار وب |
| `CF_PAGES_PROJECT` | variable | استقرار وب (پیش‌فرض `wyrd-app`) |
| `SMTP_HOST`، `SMTP_PORT`، `SMTP_USER`، `SMTP_PASS`، `SMTP_ADMIN_EMAIL`، `SMTP_SENDER_NAME` | secret | استقرار بک‌اند (SMTP سفارشی Supabase) |
| `GOOGLE_WEB_CLIENT_ID` | variable | ساخت برنامه، استقرار بک‌اند |
| `GOOGLE_CLIENT_SECRET` | secret | استقرار بک‌اند |
| `GH_OAUTH_CLIENT_ID` / `GH_OAUTH_CLIENT_SECRET` | variable / secret | استقرار بک‌اند |
| `WYRD_AUTH_GITHUB` | variable | ساخت برنامه (`true` دکمه‌ی گیت‌هاب را نشان می‌دهد) |
| `FIREBASE_API_KEY`، `FIREBASE_APP_ID_WEB`، `FIREBASE_APP_ID_ANDROID`، `FIREBASE_MESSAGING_SENDER_ID`، `FIREBASE_PROJECT_ID`، `FIREBASE_VAPID_KEY` | variable | ساخت برنامه |
| `FCM_SERVICE_ACCOUNT` | secret | استقرار بک‌اند (تابع `notify`) |
| `BACKUP_AGE_RECIPIENT` | variable | پشتیبان‌گیری |
| `ANDROID_KEYSTORE_BASE64`، `ANDROID_KEYSTORE_PASSWORD`، `ANDROID_KEY_ALIAS`، `ANDROID_KEY_PASSWORD` | secret | انتشار اندروید |

## ۱۰. اولین استقرار

ترتیب مهم است: برنامه‌ها به بک‌اند نیاز دارند.

1. **بک‌اند.** گردش‌کار استقرار بک‌اند را از زبانه‌ی **Actions** مخزن اجرا کن (یا به `main` push
   کن). این گردش‌کار migrationها، تنظیمات ورود و ایمیل و Edge Functions را اعمال می‌کند. بعد
   <https://supabase.com/dashboard/project/_/auth/url-configuration> را نگاه کن: Site URL باید همان
   `WYRD_SITE_URL` باشد و فهرست نشانی‌های بازگشت هم آن و هم `app.wyrd://auth-callback` را داشته باشد.
2. **وب.** در **Actions** گردش‌کار **Deploy web (Cloudflare Pages)** را با **Run workflow** اجرا کن،
   یا `gh workflow run deploy-web.yml`. اجرای اول پروژه‌ی Pages را می‌سازد. `https://wyrd-app.pages.dev`
   را باز کن، با کد ایمیلی حساب بساز و ورود با گوگل و گیت‌هاب را امتحان کن.
3. **اندروید.** اولین نسخه را تگ بزن:

<div dir="ltr">

```bash
git tag v1.0.0
git push origin v1.0.0
```

</div>

گردش‌کار **Release Android APK** فایل `wyrd-1.0.0.apk` را می‌سازد، بررسی می‌کند که با کلید انتشار
خودت امضا شده باشد و GitHub Release را با راهنمای نصب منتشر می‌کند. تگ نسخه را تعیین می‌کند (`v1.4.2`
یعنی 1.4.2)؛ مقدار `version:` در `app/pubspec.yaml` را هم هماهنگ نگه دار تا هشدار نگیری.

از این به بعد: هر push به `main` که `app/` یا `packages/` را تغییر دهد نسخه‌ی وب را دوباره منتشر می‌کند
و هر تگ تازه یک APK می‌سازد. اگر `CLOUDFLARE_API_TOKEN` تنظیم نشده باشد، گردش‌کار وب به‌جای خطا فقط
با یک پیام رد می‌شود.

## کاربران چطور Wyrd را نصب می‌کنند

- **هر مرورگری:** `https://wyrd-app.pages.dev` را باز کنند. Chrome و Edge روی دسکتاپ گزینه‌ی
  **Install** را در نوار نشانی نشان می‌دهند.
- **آیفون و آیپد (iOS 16.4 یا جدیدتر):** سایت را در Safari باز کنند، **Share** را بزنند (در iOS 26
  زیر دکمه‌ی **•••** است)، بعد **Add to Home Screen** را انتخاب کنند، گزینه‌ی **Open as Web App** را
  روشن بگذارند و Wyrd را از صفحه‌ی اصلی باز کنند. اعلان‌ها فقط در همین برنامه‌ی صفحه‌ی اصلی کار
  می‌کنند، بعد از این‌که وقتی برنامه اجازه خواست قبول کنند. برنامه این راهنما را یک بار در تنظیمات،
  بخش ظاهر، نشان می‌دهد.
- **اندروید:** [Obtainium](https://obtainium.imranr.dev) را نصب کنند و `https://github.com/OWNER/REPO`
  را اضافه کنند. Obtainium فایل APK را از GitHub Releases نصب می‌کند و هر به‌روزرسانی را پیشنهاد
  می‌دهد. یا فایل `wyrd-x.y.z.apk` را از صفحه‌ی Releases دانلود کنند، بازش کنند و به مرورگر اجازه‌ی نصب
  برنامه بدهند. ممکن است Play Protect تأیید بخواهد (*More details* و بعد *Install anyway*). اعلان‌ها در
  این APK هم کار می‌کنند.

گوگل در حال اجرای «تأیید توسعه‌دهنده» برای برنامه‌هایی است که بیرون از Play Store نصب می‌شوند (از
سپتامبر ۲۰۲۶ در چند کشور اجباری شده و از ۲۰۲۷ کشورهای بیشتری). پیش از این‌که به کشور کاربرانت برسد،
شرایط فعلی را در <https://developer.android.com/developer-verification> ببین.

<a id="custom-domain"></a>

## دامنه‌ی شخصی در آینده

1. یک دامنه بگیر (Cloudflare Registrar به قیمت تمام‌شده می‌فروشد:
   <https://dash.cloudflare.com/?to=/:account/domains/register>).
2. در Cloudflare بخش Workers & Pages، پروژه‌ی `wyrd-app`، **Custom domains** و بعد **Set up a custom
   domain**. اگر دامنه روی Cloudflare باشد، رکورد DNS خودکار ساخته می‌شود.
3. برنامه را به آن نشانی ببر: `gh variable set WYRD_SITE_URL --body https://your.domain` (یا گروه
   *Site address* در اسکریپت راه‌اندازی).
4. در Google Cloud، بخش Clients، کلاینت وب: `https://your.domain` را به JavaScript origins اضافه کن
   (نشانی قبلی را تا جابه‌جا شدن کاربران نگه دار). در Branding هم دامنه را به دامنه‌های مجاز اضافه کن.
   نشانی callback در Supabase عوض نمی‌شود.
5. در OAuth app گیت‌هاب، homepage URL را عوض کن. نشانی callback عوض نمی‌شود.
6. ایمیل: دامنه را در <https://resend.com/domains> اضافه کن، رکوردهای DNSی را که نشان می‌دهد در DNS
   کلادفلر بساز و صبر کن تا *Verified* شود. در <https://resend.com/api-keys> یک API key بساز و بعد
   گروه ایمیل اسکریپت راه‌اندازی را با گزینه‌ی *Resend* دوباره اجرا کن: سرور `smtp.resend.com`، درگاه
   `587`، کاربر `resend`، API key به‌عنوان رمز و فرستنده `no-reply@your.domain`.
7. همه‌چیز را دوباره منتشر کن: بک‌اند (Site URL، نشانی‌های بازگشت، SMTP)، نسخه‌ی وب (**Run
   workflow**) و یک تگ تازه برای APK.

نشانی `pages.dev` همچنان کار می‌کند. برنامه‌های صفحه‌ی اصلی آیفون به نشانی‌ای وابسته‌اند که از آن
اضافه شده‌اند، پس از کاربران آیفون بخواه یک بار نشانی تازه را اضافه کنند (داده‌های همگام‌شده‌شان بعد
از ورود برمی‌گردد).

## اگر چیزی درست کار نکرد

- **گردش‌کار وب می‌گوید «skipped»:** `CLOUDFLARE_API_TOKEN` تنظیم نشده؛ اسکریپت راه‌اندازی را اجرا کن.
- **ایمیلی نمی‌رسد:** ببین فرستنده نزد سرویس‌دهنده تأیید شده باشد، لاگ‌های Auth در Supabase و پوشه‌ی
  هرزنامه را نگاه کن.
- **ورود با گوگل روی اندروید خطا می‌دهد:** SHA-1 کلاینت اندروید باید همانی باشد که اسکریپت چاپ کرد و
  package name باید `app.wyrd` باشد.
- **بعد از یک هفته‌ی بی‌فعالیت برنامه به بک‌اند وصل نمی‌شود:** پروژه‌ی رایگان متوقف شده؛ از داشبورد
  Supabase دوباره راهش بینداز.
- **گردش‌کار انتشار در «Check signing secrets» شکست می‌خورد:** مرحله‌ی اندروید اسکریپت راه‌اندازی را
  اجرا کن.

</div>
