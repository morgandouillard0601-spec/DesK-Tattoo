#!/usr/bin/env bash
# Build Flutter web for Vercel. Env vars come from the Vercel project settings.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Writing .env for Flutter assets"
cat > .env <<EOF
APP_NAME=${APP_NAME:-DesK Tattoo}
APP_ENV=${APP_ENV:-prod}
API_BASE_URL=${API_BASE_URL:-https://api.example.com}
API_TIMEOUT_MS=${API_TIMEOUT_MS:-15000}
SUPABASE_URL=${SUPABASE_URL:?Missing SUPABASE_URL}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY:?Missing SUPABASE_ANON_KEY}
STRIPE_PUBLISHABLE_KEY=${STRIPE_PUBLISHABLE_KEY:-}
STRIPE_PRODUCT_ID=${STRIPE_PRODUCT_ID:-prod_VFctn7oeEEtvpK}
STRIPE_PRICE_ID=${STRIPE_PRICE_ID:-}
STRIPE_PRICE_LABEL=${STRIPE_PRICE_LABEL:-19,99 €}
APP_DOWNLOAD_URL=${APP_DOWNLOAD_URL:-https://desktattoo.app/get/dt-get-7f3a9c2e}
APP_STORE_URL=${APP_STORE_URL:-https://apps.apple.com/app/idXXXXXXXXX}
PLAY_STORE_URL=${PLAY_STORE_URL:-https://play.google.com/store/apps/details?id=com.desktattoo.desk_tattoo}
EOF

FLUTTER_DIR="${FLUTTER_ROOT:-$ROOT/.flutter-sdk}"
if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  echo "==> Cloning Flutter SDK (stable)"
  rm -rf "$FLUTTER_DIR"
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"
flutter --version
flutter config --no-analytics --enable-web
flutter pub get
flutter build web --release --base-href /

echo "==> Web build ready in build/web"
