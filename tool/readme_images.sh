#!/usr/bin/env bash
# Regenerates every README image: renders the app's screens, frames the
# banner and showcase art from them, then converts all of it to WebP.
# Needs Flutter, and Python 3 with Pillow.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root/app"
rm -rf build/readme
# The art frames the screens, so the screens must be rendered first.
flutter test --dart-define=SCREENSHOTS=true --update-goldens test/screenshots/readme_screenshots_test.dart
flutter test --dart-define=SCREENSHOTS=true --update-goldens test/screenshots/readme_art_test.dart
python3 "$root/tool/readme_images.py"
