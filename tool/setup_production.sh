#!/usr/bin/env bash
# Stores Wyrd's production settings as GitHub Actions secrets and variables,
# so the deploy workflows can build and ship the app. Create the accounts in
# docs/deployment.md first, then run from anywhere in the repository:
#
#   tool/setup_production.sh [--repo OWNER/REPO]
#
# Every group can be skipped and the script can be re-run at any time: press
# Enter to keep a value that is already stored. Passwords, tokens and keys are
# read without echo, passed to gh on stdin and never written to disk.
# Works with the bash 3.2 that ships with macOS.
set -euo pipefail

repo=""
while [ $# -gt 0 ]; do
  case "$1" in
    --repo)
      repo="${2:-}"
      [ -n "$repo" ] || {
        echo "--repo needs OWNER/REPO" >&2
        exit 2
      }
      shift 2
      ;;
    -h | --help)
      sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Unknown option: $1 (try --help)" >&2
      exit 2
      ;;
  esac
done

if [ -t 1 ]; then
  bold=$'\033[1m' dim=$'\033[2m' reset=$'\033[0m'
else
  bold="" dim="" reset=""
fi

say() { printf '%s\n' "$*"; }
note() { printf '%s%s%s\n' "$dim" "$*" "$reset"; }
die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

# Hidden input turns terminal echo off; turn it back on if interrupted.
trap 'stty echo 2>/dev/null || true; printf "\n"; exit 130' INT

# ask "Prompt" [default] -> prints the answer (the prompt goes to stderr).
ask() {
  local prompt="$1" default="${2:-}" reply=""
  if [ -n "$default" ]; then prompt="$prompt [$default]"; fi
  read -r -p "$prompt: " reply || true
  printf '%s' "${reply:-$default}"
}

# ask_secret "Prompt" -> prints the answer; nothing is echoed while typing.
ask_secret() {
  local reply=""
  read -r -s -p "$1: " reply || true
  printf '\n' >&2
  printf '%s' "$reply"
}

# confirm "Question" [Y|N] -> succeeds on yes.
confirm() {
  local default="${2:-Y}" reply=""
  if [ "$default" = "Y" ]; then
    read -r -p "$1 [Y/n] " reply || true
  else
    read -r -p "$1 [y/N] " reply || true
  fi
  case "${reply:-$default}" in
    [yY]*) return 0 ;;
    *) return 1 ;;
  esac
}

# group "Title" "what it is for" -> succeeds when the user wants to set it now.
group() {
  local reply=""
  printf '\n%s== %s ==%s\n' "$bold" "$1" "$reset"
  note "$2"
  read -r -p "Set this up now? [Y/n/q] " reply || true
  case "$reply" in
    [nN]*)
      say "  skipped"
      return 1
      ;;
    [qQ]*)
      say "Stopped. Run the script again to continue."
      exit 0
      ;;
    *) return 0 ;;
  esac
}

stored_secrets="" # names of the secrets already stored, one per line
has_secret() {
  case $'\n'"$stored_secrets"$'\n' in
    *$'\n'"$1"$'\n'*) return 0 ;;
    *) return 1 ;;
  esac
}
current_variable() { gh variable get "$1" --repo "$repo" 2>/dev/null || true; }

# set_secret NAME VALUE: the value reaches gh on stdin, never on a command line.
set_secret() {
  if [ -z "$2" ]; then
    if has_secret "$1"; then say "  = secret $1 kept"; else say "  - secret $1 not set (empty)"; fi
    return 0
  fi
  printf '%s' "$2" | gh secret set "$1" --repo "$repo" >/dev/null
  say "  ✓ secret $1"
}

set_variable() {
  if [ -z "$2" ]; then
    say "  - variable $1 not set (empty)"
    return 0
  fi
  gh variable set "$1" --repo "$repo" --body "$2" >/dev/null
  say "  ✓ variable $1"
}

# secret_prompt NAME "Prompt" -> asks without echo; Enter keeps a stored value.
secret_prompt() {
  local hint=""
  if has_secret "$1"; then hint=" (Enter keeps the stored one)"; fi
  ask_secret "$2$hint"
}

# variable_prompt NAME "Prompt" [fallback default] -> visible; defaults to the stored value.
variable_prompt() {
  local stored
  stored="$(current_variable "$1")"
  ask "$2" "${stored:-${3:-}}"
}

warn_unless() { # warn_unless VALUE REGEX "message"
  if [ -n "$1" ] && ! [[ "$1" =~ $2 ]]; then note "  ! $3"; fi
}

# Creates (or reuses) the APK upload key and stores it. Anything missing skips
# the rest of this group instead of ending the script.
setup_android_key() {
  local keystore="" alias_name="" store_pass="" key_pass="" repeat="" owner_name="" fingerprints=""
  if ! command -v keytool >/dev/null 2>&1; then
    say "  ! keytool not found: install a JDK (Android Studio ships one), then run the script again"
    return 0
  fi
  if confirm "Create a new upload keystore with keytool?" Y; then
    keystore="$(ask "Save it as" "${XDG_CONFIG_HOME:-$HOME/.config}/wyrd/wyrd-upload.jks")"
    keystore="${keystore/#\~/$HOME}"
    if [ -e "$keystore" ]; then
      say "  ! $keystore already exists: run again and answer n to use it"
      return 0
    fi
    alias_name="$(ask "Key alias" upload)"
    while :; do
      store_pass="$(ask_secret "Keystore password (6+ characters)")"
      if [ "${#store_pass}" -lt 6 ]; then
        say "  too short"
        continue
      fi
      repeat="$(ask_secret "Repeat the password")"
      if [ "$repeat" != "$store_pass" ]; then
        say "  the passwords differ"
        continue
      fi
      break
    done
    key_pass="$store_pass" # PKCS12 keystores use one password for both
    owner_name="$(ask "Name on the certificate" Wyrd)"
    mkdir -p "$(dirname "$keystore")"
    WYRD_KEYSTORE_PASS="$store_pass" keytool -genkeypair -keystore "$keystore" -storetype PKCS12 \
      -alias "$alias_name" -keyalg RSA -keysize 4096 -validity 10000 -dname "CN=$owner_name" \
      -storepass:env WYRD_KEYSTORE_PASS -keypass:env WYRD_KEYSTORE_PASS >/dev/null
    chmod 600 "$keystore"
    say "  Created $keystore"
  else
    keystore="$(ask "Existing keystore file")"
    keystore="${keystore/#\~/$HOME}"
    if [ ! -f "$keystore" ]; then
      say "  ! $keystore not found"
      return 0
    fi
    alias_name="$(ask "Key alias" upload)"
    store_pass="$(ask_secret "Keystore password")"
    key_pass="$(ask_secret "Key password (Enter if the same)")"
    key_pass="${key_pass:-$store_pass}"
  fi
  if ! fingerprints="$(WYRD_KEYSTORE_PASS="$store_pass" keytool -list -v -keystore "$keystore" \
    -alias "$alias_name" -storepass:env WYRD_KEYSTORE_PASS 2>/dev/null)"; then
    say "  ! the keystore does not open with that password or has no key named $alias_name; nothing stored"
    return 0
  fi
  say
  say "  ${bold}Signing certificate SHA-256${reset} (every release's notes show it, so people can check an APK is yours):"
  printf '%s\n' "$fingerprints" | grep -E '^[[:space:]]*SHA256:' | sed 's/^[[:space:]]*/    /' || true
  say
  base64 <"$keystore" | tr -d '\n' | gh secret set ANDROID_KEYSTORE_BASE64 --repo "$repo" >/dev/null
  say "  ✓ secret ANDROID_KEYSTORE_BASE64"
  set_secret ANDROID_KEYSTORE_PASSWORD "$store_pass"
  set_secret ANDROID_KEY_ALIAS "$alias_name"
  set_secret ANDROID_KEY_PASSWORD "$key_pass"
  note "  Back up $keystore and its password. If they are lost, phones can only"
  note "  install a newer Wyrd after uninstalling the old one (and losing local data)."
}

# --- Preconditions ------------------------------------------------------------

cd "$(dirname "${BASH_SOURCE[0]}")/.." || die "cannot find the repository root"
[ -f app/pubspec.yaml ] || die "run this script from the Wyrd repository"
command -v gh >/dev/null 2>&1 || die "install the GitHub CLI first: https://cli.github.com"
gh auth status >/dev/null 2>&1 || die "sign in to GitHub first: gh auth login"

if [ -z "$repo" ]; then
  repo="$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null || true)"
  [ -n "$repo" ] || die "could not tell which GitHub repository this is; pass --repo OWNER/REPO"
fi
say "${bold}Wyrd production setup${reset} for ${bold}$repo${reset}"
note "Values go to Settings > Secrets and variables > Actions of this repository."
confirm "Continue with $repo?" Y || exit 0
stored_secrets="$(gh secret list --repo "$repo" 2>/dev/null | cut -f1 || true)"

# --- 1. Supabase ----------------------------------------------------------------

if group "Supabase" "Backend project, its API keys and the CLI token the backend deploy uses (docs/deployment.md, step 1)."; then
  ref="$(ask "Project ref (from https://supabase.com/dashboard/project/<ref>)")"
  warn_unless "$ref" '^[a-z0-9]{20}$' "a project ref is usually 20 lowercase letters"
  set_secret SUPABASE_PROJECT_ID "$ref"
  default_url=""
  if [ -n "$ref" ]; then default_url="https://$ref.supabase.co"; fi
  url="$(variable_prompt SUPABASE_URL "Project URL" "$default_url")"
  set_variable SUPABASE_URL "${url%/}"
  key="$(variable_prompt SUPABASE_PUBLISHABLE_KEY "Publishable key (sb_publishable_...)")"
  case "$key" in
    sb_secret_*)
      # Variables are public: never store a secret key as one.
      say "  ! that is a secret key, not the publishable one; SUPABASE_PUBLISHABLE_KEY not changed"
      ;;
    *)
      warn_unless "$key" '^sb_publishable_' "that does not look like a publishable key"
      set_variable SUPABASE_PUBLISHABLE_KEY "$key"
      ;;
  esac
  secret_key="$(secret_prompt SUPABASE_SECRET_KEY "Secret key (sb_secret_...; the backend deploy keeps it in the database Vault)")"
  warn_unless "$secret_key" '^sb_secret_' "secret keys start with sb_secret_"
  set_secret SUPABASE_SECRET_KEY "$secret_key"
  token="$(secret_prompt SUPABASE_ACCESS_TOKEN "Personal access token (sbp_..., https://supabase.com/dashboard/account/tokens)")"
  warn_unless "$token" '^sbp_' "personal access tokens start with sbp_"
  set_secret SUPABASE_ACCESS_TOKEN "$token"
  set_secret SUPABASE_DB_PASSWORD "$(secret_prompt SUPABASE_DB_PASSWORD "Database password")"
fi

# --- 2. Cloudflare --------------------------------------------------------------

pages_project="$(current_variable CF_PAGES_PROJECT)"
pages_project="${pages_project:-wyrd-app}"
if group "Cloudflare Pages" "Hosting for the web app; the deploy workflow creates the Pages project on its first run (step 2)."; then
  set_secret CLOUDFLARE_API_TOKEN "$(secret_prompt CLOUDFLARE_API_TOKEN "API token with Account > Cloudflare Pages > Edit")"
  account="$(ask "Account ID (32 characters, Workers & Pages overview)")"
  warn_unless "$account" '^[0-9a-f]{32}$' "an account ID is 32 hexadecimal characters"
  set_secret CLOUDFLARE_ACCOUNT_ID "$account"
  pages_project="$(ask "Pages project name (wyrd is taken)" "$pages_project")"
  warn_unless "$pages_project" '^[a-z0-9][a-z0-9-]*$' "use lowercase letters, digits and dashes"
  set_variable CF_PAGES_PROJECT "$pages_project"
fi

# --- Site address ---------------------------------------------------------------

if group "Site address" "The one public URL everything else uses (sign-in redirects, the backend's Site URL, release notes). Change it here when you move to your own domain."; then
  site="$(variable_prompt WYRD_SITE_URL "Site URL" "https://$pages_project.pages.dev")"
  site="${site%/}"
  warn_unless "$site" '^https://' "the site must be served over https"
  set_variable WYRD_SITE_URL "$site"
fi

# --- 3. E-mail ------------------------------------------------------------------

if group "E-mail sender (SMTP)" "Sign-in codes and password resets. Supabase's built-in mailer only reaches your team (step 3)."; then
  say "  1) Brevo (free, 300 e-mails a day, verified sender address)"
  say "  2) Gmail with an app password"
  say "  3) Resend (needs your own domain)"
  say "  4) Other SMTP server"
  provider="$(ask "Provider" 1)"
  host="" port=587 user="" sender="" pass_hint="SMTP password"
  case "$provider" in
    1) host="smtp-relay.brevo.com" pass_hint="SMTP key (Brevo > SMTP & API > SMTP)" ;;
    2) host="smtp.gmail.com" pass_hint="16-character app password (https://myaccount.google.com/apppasswords)" ;;
    3) host="smtp.resend.com" user="resend" pass_hint="Resend API key (re_...)" ;;
    *) ;;
  esac
  host="$(ask "SMTP host" "$host")"
  port="$(ask "SMTP port" "$port")"
  warn_unless "$port" '^[0-9]+$' "the port is a number such as 587 or 465"
  if [ "$provider" = 1 ]; then note "  Brevo's SMTP login looks like 1a2b3c001@smtp-brevo.com (not your account e-mail)."; fi
  user="$(ask "SMTP user" "$user")"
  if [ "$provider" = 2 ]; then sender="$user"; fi
  sender="$(ask "Sender address (verified with the provider)" "$sender")"
  warn_unless "$sender" '^[^@ ]+@[^@ ]+$' "the sender should be an e-mail address"
  sender_name="$(ask "Sender name" "Wyrd")"
  set_secret SMTP_HOST "$host"
  set_secret SMTP_PORT "$port"
  set_secret SMTP_USER "$user"
  set_secret SMTP_PASS "$(secret_prompt SMTP_PASS "$pass_hint")"
  set_secret SMTP_ADMIN_EMAIL "$sender"
  set_secret SMTP_SENDER_NAME "$sender_name"
fi

# --- 4. Firebase ----------------------------------------------------------------

if group "Firebase Cloud Messaging" "Push notifications: the web and Android app config, the web push key and the server's service account (step 4)."; then
  set_variable FIREBASE_PROJECT_ID "$(variable_prompt FIREBASE_PROJECT_ID "Project ID")"
  set_variable FIREBASE_API_KEY "$(variable_prompt FIREBASE_API_KEY "Web API key (apiKey, AIza...)")"
  set_variable FIREBASE_MESSAGING_SENDER_ID "$(variable_prompt FIREBASE_MESSAGING_SENDER_ID "Sender ID (messagingSenderId)")"
  set_variable FIREBASE_APP_ID_WEB "$(variable_prompt FIREBASE_APP_ID_WEB "Web app ID (1:...:web:...)")"
  set_variable FIREBASE_APP_ID_ANDROID "$(variable_prompt FIREBASE_APP_ID_ANDROID "Android app ID (1:...:android:...)")"
  set_variable FIREBASE_VAPID_KEY "$(variable_prompt FIREBASE_VAPID_KEY "Web push certificate key pair (VAPID public key)")"
  account_file="$(ask "Service-account JSON file (Enter to skip)")"
  account_file="${account_file/#\~/$HOME}"
  if [ -n "$account_file" ]; then
    if [ ! -f "$account_file" ]; then
      say "  ! $account_file not found; FCM_SERVICE_ACCOUNT not set"
    elif ! grep -q '"type": *"service_account"' "$account_file"; then
      say "  ! that file is not a service-account key; FCM_SERVICE_ACCOUNT not set"
    else
      gh secret set FCM_SERVICE_ACCOUNT --repo "$repo" <"$account_file" >/dev/null
      say "  ✓ secret FCM_SERVICE_ACCOUNT"
      note "  Delete the downloaded key file once you no longer need it: GitHub now holds a copy."
    fi
  fi
fi

# --- 5. GitHub sign-in ----------------------------------------------------------

if group "GitHub sign-in" "OAuth app from GitHub developer settings (step 5). GitHub reserves names starting with GITHUB_, so these are stored as GH_OAUTH_*."; then
  set_variable GH_OAUTH_CLIENT_ID "$(variable_prompt GH_OAUTH_CLIENT_ID "Client ID")"
  set_secret GH_OAUTH_CLIENT_SECRET "$(secret_prompt GH_OAUTH_CLIENT_SECRET "Client secret")"
  if confirm "Show the GitHub button in the app?" Y; then
    set_variable WYRD_AUTH_GITHUB true
  else
    set_variable WYRD_AUTH_GITHUB false
  fi
fi

# --- 6. Android -----------------------------------------------------------------

if group "Android release key" "Signs the APK on GitHub Releases. Every update must be signed with the same key: back it up (step 6)."; then
  setup_android_key
fi

# --- 7. Backups -----------------------------------------------------------------

if group "Encrypted backups" "Database dumps are encrypted to an age public key; only you keep the private key (step 7)."; then
  recipient="$(current_variable BACKUP_AGE_RECIPIENT)"
  if [ -n "$recipient" ]; then
    recipient="$(ask "age public key" "$recipient")"
  else
    recipient="$(ask "age public key (age1...; Enter to create a new key pair)")"
  fi
  if [ -z "$recipient" ]; then
    if command -v age-keygen >/dev/null 2>&1; then
      key_file="$(ask "Where to save the private key" "${XDG_CONFIG_HOME:-$HOME/.config}/wyrd/wyrd-backup-key.txt")"
      key_file="${key_file/#\~/$HOME}"
      if [ -e "$key_file" ]; then
        say "  Using the existing key in $key_file"
      else
        mkdir -p "$(dirname "$key_file")"
        (umask 077 && age-keygen -o "$key_file" 2>/dev/null)
        say "  Created $key_file"
      fi
      recipient="$(age-keygen -y "$key_file")"
      note "  Keep a copy of $key_file somewhere safe and offline (a password manager works)."
      note "  Without it no backup can be decrypted."
    else
      say "  ! age-keygen not found (https://github.com/FiloSottile/age); BACKUP_AGE_RECIPIENT not set"
    fi
  fi
  warn_unless "$recipient" '^age1' "age public keys start with age1"
  set_variable BACKUP_AGE_RECIPIENT "$recipient"
fi

# --- Done -----------------------------------------------------------------------

printf '\n%sDone.%s Next (docs/deployment.md, "First deploy"):\n' "$bold" "$reset"
say "  1. Deploy the backend (Actions tab, backend deploy workflow)."
say "  2. Deploy the web app: gh workflow run deploy-web.yml --repo $repo"
say "  3. Release the Android app: git tag v1.0.0 && git push origin v1.0.0"
