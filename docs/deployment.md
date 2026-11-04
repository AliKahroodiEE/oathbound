# Deploying Wyrd to production

[فارسی](deployment.fa.md)

The owner's checklist for running Wyrd for real users at **$0 a month**. Do the steps in
order once; afterwards every push to `main` redeploys the web app and every `v*` tag publishes
a new Android release.

| Piece | Where it runs | How it ships |
| --- | --- | --- |
| Web app (also the iPhone app) | Cloudflare Pages, `https://wyrd-app.pages.dev` | [`deploy-web.yml`](../.github/workflows/deploy-web.yml) on push to `main` |
| Backend (database, sign-in, Edge Functions) | Supabase Free | the backend deploy workflow (see [backend/README.md](../backend/README.md)) |
| Android app | Signed APK on GitHub Releases | [`release-android.yml`](../.github/workflows/release-android.yml) on a `v*` tag |
| Sign-in e-mails | Brevo (or Gmail) over SMTP | Supabase custom SMTP |
| Push notifications | Firebase Cloud Messaging | the `notify` Edge Function |

The public address lives in **one** place: the GitHub repository variable `WYRD_SITE_URL`.
Everything that needs it (the web build, the APK, Supabase's redirect settings) reads that
variable, so moving to your own domain later is a short procedure
([Custom domain later](#custom-domain-later)).

## Free-tier limits

| Service | Free allowance | Watch out for |
| --- | --- | --- |
| Supabase | 500 MB database, 5 GB egress a month, 50,000 monthly active users, 1 GB file storage, 500,000 Edge Function calls a month | The project **pauses after 7 days without database activity** (restore it from the dashboard). **No automatic backups**: step 7 covers that. |
| Cloudflare Pages | Static requests and bandwidth unlimited | At most 20,000 files per deployment, 25 MiB per file (the web build is far below). |
| Brevo | 300 e-mails a day | Sender address must be verified; without your own domain some mail lands in spam. |
| Gmail (alternative) | About 500 e-mails a day | Needs 2-Step Verification and an app password. |
| Resend (later, own domain) | 3,000 e-mails a month, 100 a day | Needs DNS records on your domain. |
| Firebase Cloud Messaging | Free | — |
| GitHub | Actions free for public repositories, Releases free | Private repositories get 2,000 Actions minutes a month. |

## What you need

- A GitHub account with admin rights on this repository, and the [GitHub CLI](https://cli.github.com)
  signed in: `gh auth login`.
- A JDK for `keytool` (Android Studio ships one) to create the Android signing key.
- [age](https://github.com/FiloSottile/age) for encrypted backups (`brew install age`,
  `sudo apt install age` or `winget install FiloSottile.age`).
- A password manager. Several values below are shown only once.

Collect the values in steps 1–7, then run `tool/setup_production.sh` (step 9), which stores
them in GitHub. Names in `code` are the GitHub secrets (private) and variables (public client
configuration) they end up in; the script asks for each one.

## 1. Supabase project

1. Create the project at <https://supabase.com/dashboard/new>: name `wyrd`, a long generated
   **database password** (save it: `SUPABASE_DB_PASSWORD`) and the **region closest to most
   of your users** (for Europe and the Middle East, Frankfurt is a good default). The Free plan
   allows two active projects.
2. The **project ref** is the id in the dashboard URL,
   `https://supabase.com/dashboard/project/<ref>`: `SUPABASE_PROJECT_ID`. The **project URL**
   is `https://<ref>.supabase.co`: `SUPABASE_URL`.
3. API keys, <https://supabase.com/dashboard/project/_/settings/api-keys>: copy the
   **publishable key** (`sb_publishable_…`): `SUPABASE_PUBLISHABLE_KEY`. New projects have no
   legacy `anon`/`service_role` keys; the `sb_secret_…` keys never leave Supabase (Edge
   Functions receive them automatically).
4. Personal access token for the deploy workflow, <https://supabase.com/dashboard/account/tokens>:
   **Generate new token**: `SUPABASE_ACCESS_TOKEN`.
5. Lost the database password? Reset it at
   <https://supabase.com/dashboard/project/_/database/settings>.

Nothing else is clicked in the dashboard: sign-in providers, redirect URLs, SMTP and e-mail
templates come from `backend/supabase/config.toml` and are applied by the backend deploy.
Tables are not exposed to the Data API automatically on new projects; the migrations grant
exactly what the app uses.

## 2. Cloudflare account

1. Sign up at <https://dash.cloudflare.com/sign-up> (free plan, no card needed).
2. **Account ID**: open <https://dash.cloudflare.com/?to=/:account/workers-and-pages> and copy
   the Account ID from the side panel: `CLOUDFLARE_ACCOUNT_ID`.
3. **API token**: <https://dash.cloudflare.com/profile/api-tokens> → **Create Token** →
   **Create Custom Token**. Permissions: *Account* · *Cloudflare Pages* · *Edit*. Account
   resources: *Include* · your account. Save it: `CLOUDFLARE_API_TOKEN`.
4. Pages project name: `wyrd-app` (`wyrd` is taken): `CF_PAGES_PROJECT`. You do not create it
   by hand; the first deploy does.

## 3. E-mail sender

Sign-in codes, sign-up confirmations and password resets are 6-digit codes sent by e-mail.
Supabase's built-in mailer only reaches members of your Supabase team (2 an hour), so
production needs its own SMTP account. Pick one:

**Brevo (recommended for now).** Free, 300 e-mails a day, no domain needed.

1. Sign up at <https://www.brevo.com>.
2. Add and verify the sender address you will send from (a mailbox you own):
   <https://app.brevo.com/senders/list>. This is `SMTP_ADMIN_EMAIL`.
3. SMTP settings, <https://app.brevo.com/settings/keys/smtp>: server `smtp-relay.brevo.com`
   (`SMTP_HOST`), port `587` (`SMTP_PORT`), the **login** shown there, which looks like
   `…@smtp-brevo.com` (`SMTP_USER`), and a new **SMTP key** (`SMTP_PASS`).

**Gmail.** Uses your Google account; about 500 e-mails a day.

1. Turn on 2-Step Verification: <https://myaccount.google.com/signinoptions/twosv>.
2. Create an app password named `Wyrd`: <https://myaccount.google.com/apppasswords> (16
   characters, `SMTP_PASS`).
3. Server `smtp.gmail.com`, port `587`, user and sender = your Gmail address.

The sender name (`SMTP_SENDER_NAME`) is `Wyrd`. Without your own domain, ask testers to check
their spam folder the first time. Once you have a domain, switch to Resend
([Custom domain later](#custom-domain-later)).

## 4. Google sign-in

Google Cloud console, signed in with the account that should own the app:

1. Create a project: <https://console.cloud.google.com/projectcreate> (you can reuse it for
   Firebase in step 6).
2. **Branding** (consent screen), <https://console.cloud.google.com/auth/branding>: app name
   `Wyrd`, support e-mail, home page `WYRD_SITE_URL`, authorized domains `wyrd-app.pages.dev`
   (later your own domain) and `<ref>.supabase.co`. **Audience**, <https://console.cloud.google.com/auth/audience>: *External*,
   then **Publish app**. **Data access**, <https://console.cloud.google.com/auth/scopes>: only
   `openid`, `…/auth/userinfo.email` and `…/auth/userinfo.profile`. These are non-sensitive,
   so Google does not review the app.
3. **Web client**, <https://console.cloud.google.com/auth/clients> → **Create client** →
   *Web application*:
   - Authorized JavaScript origins: `https://wyrd-app.pages.dev` (your `WYRD_SITE_URL`).
   - Authorized redirect URIs: `https://<ref>.supabase.co/auth/v1/callback`.
   - Copy the **client ID** (`GOOGLE_WEB_CLIENT_ID`) and **client secret**
     (`GOOGLE_CLIENT_SECRET`).
4. **Android client**: **Create client** → *Android*, package name `app.wyrd`, and the
   **SHA-1 of the release key**. `tool/setup_production.sh` prints it when it creates the key
   (step 8), so you can come back to this after step 9. No value from this client goes into
   GitHub; it only has to exist. For signing in from your own debug builds, add a second
   Android client with the debug key's SHA-1
   (`keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android`).

## 5. GitHub sign-in

1. New OAuth app: <https://github.com/settings/applications/new> (an *OAuth App*, not a
   GitHub App).
   - Application name `Wyrd`, homepage URL `WYRD_SITE_URL`.
   - Authorization callback URL: `https://<ref>.supabase.co/auth/v1/callback`.
2. **Generate a new client secret**. Copy the client ID and the secret.

GitHub does not allow secret or variable names that start with `GITHUB_`, so they are stored
as `GH_OAUTH_CLIENT_ID` (variable) and `GH_OAUTH_CLIENT_SECRET` (secret).
`WYRD_AUTH_GITHUB=true` shows the GitHub button in the app. Phones come back to the app
through `app.wyrd://auth-callback`; the backend configuration allows that redirect.

## 6. Firebase (push notifications)

1. <https://console.firebase.google.com> → **Create a project** (or add Firebase to the Google
   Cloud project from step 4). Google Analytics is not needed.
2. **Web app**: Project settings → *Your apps* → add a web app (`</>`), name `Wyrd`, no
   Hosting. From the config it shows: `apiKey` → `FIREBASE_API_KEY`, `appId` →
   `FIREBASE_APP_ID_WEB`, `messagingSenderId` → `FIREBASE_MESSAGING_SENDER_ID`, `projectId` →
   `FIREBASE_PROJECT_ID`.
3. **Android app**: add an Android app with package name `app.wyrd`. Its App ID
   (`1:…:android:…`) → `FIREBASE_APP_ID_ANDROID`. The app is configured from these values at
   build time; `google-services.json` is not needed (and stays out of git).
4. **Web push key**: <https://console.firebase.google.com/project/_/settings/cloudmessaging> →
   *Web configuration* → **Generate key pair**. The public key → `FIREBASE_VAPID_KEY`.
5. **Server key** for the `notify` function:
   <https://console.firebase.google.com/project/_/settings/serviceaccounts/adminsdk> →
   **Generate new private key**. Keep the downloaded JSON file outside the repository; the
   setup script reads it into `FCM_SERVICE_ACCOUNT`, then you can delete it.

Firebase web config values are public by design; only the service-account key is secret.

## 7. Backups

Free Supabase projects have no automatic backups. Backups are encrypted to an
[age](https://github.com/FiloSottile/age) key, so they can be stored anywhere and only you can
read them:

```bash
mkdir -p ~/.config/wyrd
age-keygen -o ~/.config/wyrd/wyrd-backup-key.txt   # prints "Public key: age1…"
```

- The public key (`age1…`) → `BACKUP_AGE_RECIPIENT` (a variable; it can only encrypt).
- The key file is the only way to decrypt. Put a copy in your password manager or another
  offline place. Never commit it or store it in GitHub.
- To read a backup: `age --decrypt -i ~/.config/wyrd/wyrd-backup-key.txt <file>.age > <file>`.

The setup script can run `age-keygen` for you.

## 8. Android signing key

The APK must be signed with the same key forever: Android only installs an update over an
existing app when the signatures match. The setup script creates the key with `keytool`
(4096-bit RSA, valid for 27 years), prints its SHA-1 for step 4 and stores it in GitHub as
`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` and
`ANDROID_KEY_PASSWORD`.

**Back up the keystore file and its password.** If they are lost, users can only install a
newer Wyrd after uninstalling the old one, which deletes its local data.

To sign release builds on your own machine, copy `app/android/key.properties.example` to
`app/android/key.properties` (gitignored) and fill it in. Without it, local release builds
are signed with the debug key.

## 9. Store everything in GitHub

From the repository:

```bash
gh auth login                    # once
tool/setup_production.sh         # or: tool/setup_production.sh --repo OWNER/REPO
```

The script walks through the groups above, lets you skip any of them and can be re-run at any
time (Enter keeps a stored value). Passwords, tokens and keys are typed without echo and
handed to `gh` on stdin. You can check the result at
`https://github.com/OWNER/REPO/settings/secrets/actions` (secrets and variables tabs).

| Name | Kind | Used by |
| --- | --- | --- |
| `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` | variables | web and Android builds |
| `SUPABASE_PROJECT_ID`, `SUPABASE_ACCESS_TOKEN`, `SUPABASE_DB_PASSWORD` | secrets | backend deploy |
| `WYRD_SITE_URL` | variable | everything that needs the public address |
| `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID` | secrets | web deploy |
| `CF_PAGES_PROJECT` | variable | web deploy (default `wyrd-app`) |
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `SMTP_ADMIN_EMAIL`, `SMTP_SENDER_NAME` | secrets | backend deploy (Supabase custom SMTP) |
| `GOOGLE_WEB_CLIENT_ID` | variable | builds, backend deploy |
| `GOOGLE_CLIENT_SECRET` | secret | backend deploy |
| `GH_OAUTH_CLIENT_ID` / `GH_OAUTH_CLIENT_SECRET` | variable / secret | backend deploy |
| `WYRD_AUTH_GITHUB` | variable | builds (`true` shows the GitHub button) |
| `FIREBASE_API_KEY`, `FIREBASE_APP_ID_WEB`, `FIREBASE_APP_ID_ANDROID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID`, `FIREBASE_VAPID_KEY` | variables | builds |
| `FCM_SERVICE_ACCOUNT` | secret | backend deploy (`notify` function) |
| `BACKUP_AGE_RECIPIENT` | variable | backups |
| `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | secrets | Android release |

## 10. First deploy

Order matters: the apps need a backend to talk to.

1. **Backend.** Run the backend deploy workflow from the repository's **Actions** tab (or push
   to `main`). It applies the migrations, the auth and SMTP settings and the Edge Functions.
   Then check <https://supabase.com/dashboard/project/_/auth/url-configuration>: the Site URL is
   your `WYRD_SITE_URL` and the redirect list contains it and `app.wyrd://auth-callback`.
2. **Web.** **Actions** → **Deploy web (Cloudflare Pages)** → **Run workflow**, or
   `gh workflow run deploy-web.yml`. The first run creates the Pages project. Open
   `https://wyrd-app.pages.dev`, create an account with an e-mail code and try Google and
   GitHub sign-in.
3. **Android.** Tag the first release:

   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

   **Release Android APK** builds `wyrd-1.0.0.apk`, checks it is signed with your release key
   and publishes the GitHub Release with install notes. The tag sets the version (`v1.4.2` →
   1.4.2); keep `version:` in `app/pubspec.yaml` in step to avoid a warning.

From then on: pushes to `main` that touch `app/` or `packages/` redeploy the web app, and each
new tag ships an APK. If `CLOUDFLARE_API_TOKEN` is missing, the web workflow skips with a
notice instead of failing.

## How people install Wyrd

- **Any browser:** open `https://wyrd-app.pages.dev`. Chrome and Edge on desktop offer
  **Install** in the address bar.
- **iPhone and iPad (iOS 16.4 or newer):** open the site in Safari, tap **Share** (on iOS 26
  it is under the **•••** button), then **Add to Home Screen**, keep **Open as Web App** on and
  open Wyrd from the Home Screen. Notifications only work in this Home Screen app, after
  allowing them when the app asks. The app shows this tip once under Settings → Appearance.
- **Android:** install [Obtainium](https://obtainium.imranr.dev), then add
  `https://github.com/OWNER/REPO`. Obtainium installs the APK from GitHub Releases and offers
  each update. Or download `wyrd-x.y.z.apk` from the Releases page, open it and allow the
  browser to install apps. Play Protect may ask for confirmation (*More details* →
  *Install anyway*). Push notifications work in this APK too.

Google is rolling out developer verification for apps installed outside the Play Store
(enforced in a few countries since September 2026, more from 2027). Check the current
requirements at <https://developer.android.com/developer-verification> before they reach your
users' countries.

## Custom domain later

1. Get a domain (Cloudflare Registrar sells at cost:
   <https://dash.cloudflare.com/?to=/:account/domains/register>).
2. Cloudflare → Workers & Pages → `wyrd-app` → **Custom domains** → **Set up a custom
   domain**. With the domain on Cloudflare, the DNS record is created for you.
3. Point the app at it: `gh variable set WYRD_SITE_URL --body https://your.domain` (or the
   *Site address* group of the setup script).
4. Google Cloud → Clients → the web client: add `https://your.domain` to the JavaScript
   origins (keep the old one until people have moved). Branding: add the domain to the
   authorized domains. The Supabase callback URL does not change.
5. GitHub OAuth app: change the homepage URL. The callback URL does not change.
6. E-mail: add the domain at <https://resend.com/domains>, create the DNS records it lists in
   Cloudflare DNS and wait for *Verified*. Create an API key at <https://resend.com/api-keys>,
   then re-run the setup script's e-mail group with *Resend*: host `smtp.resend.com`, port
   `587`, user `resend`, the API key as password, sender `no-reply@your.domain`.
7. Redeploy everything: the backend (Site URL, redirects, SMTP), the web app (**Run
   workflow**) and a new APK tag.

The `pages.dev` address keeps working. Home Screen apps on iPhone belong to the address they
were added from, so ask iPhone users to add the new address once (their synced data comes back
after signing in).

## If something goes wrong

- **Web workflow says "skipped":** `CLOUDFLARE_API_TOKEN` is not set; run the setup script.
- **No e-mails:** check the sender is verified at the provider, look at the Auth logs in
  Supabase, and the spam folder.
- **Google sign-in fails on Android:** the Android OAuth client's SHA-1 must be the one the
  setup script printed, and package name `app.wyrd`.
- **The app cannot reach the backend after a quiet week:** the Free project paused; restore it
  from the Supabase dashboard.
- **Release workflow fails at "Check signing secrets":** run the setup script's Android step.
