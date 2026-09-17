#!/usr/bin/env bash
# Build Flutter web pour l'hébergeur statique (Netlify).
# Les variables viennent des réglages d'environnement du site.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Netlify expose l'URL du site dans `URL` (et celle du deploy preview dans
# `DEPLOY_PRIME_URL`). On s'en sert par défaut pour le lien du QR d'accueil.
DEFAULT_WEB_APP_URL="${WEB_APP_URL:-${DEPLOY_PRIME_URL:-${URL:-}}}"

# Ne jamais echo ces valeurs : le secret scanning Netlify échoue sinon.
: "${SUPABASE_URL:?Missing SUPABASE_URL — variable d'environnement Netlify.}"
: "${SUPABASE_ANON_KEY:?Missing SUPABASE_ANON_KEY — variable d'environnement Netlify.}"

echo "==> Writing .env for Flutter assets"
echo "    WEB_APP_URL=${DEFAULT_WEB_APP_URL:-<vide>}"
echo "    SUPABASE_URL / SUPABASE_ANON_KEY are set (values omitted)"
cat > .env <<EOF
APP_NAME=${APP_NAME:-DesK Tattoo}
APP_ENV=${APP_ENV:-prod}
API_BASE_URL=${API_BASE_URL:-https://api.example.com}
API_TIMEOUT_MS=${API_TIMEOUT_MS:-15000}
WEB_APP_URL=${DEFAULT_WEB_APP_URL}
SUPABASE_URL=${SUPABASE_URL}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
STRIPE_PUBLISHABLE_KEY=${STRIPE_PUBLISHABLE_KEY:-}
STRIPE_PRODUCT_ID=${STRIPE_PRODUCT_ID:-prod_VFctn7oeEEtvpK}
STRIPE_PRICE_ID=${STRIPE_PRICE_ID:-}
STRIPE_PRICE_LABEL=${STRIPE_PRICE_LABEL:-19,99 €}
APP_DOWNLOAD_URL=${APP_DOWNLOAD_URL:-https://desktattoo.app/get/dt-get-7f3a9c2e}
APP_STORE_URL=${APP_STORE_URL:-https://apps.apple.com/app/idXXXXXXXXX}
PLAY_STORE_URL=${PLAY_STORE_URL:-https://play.google.com/store/apps/details?id=com.desktattoo.desk_tattoo}
EOF

# .env est dans .gitignore : Flutter ne l'embarque pas dans le bundle web.
# On passe les clés via dart-define (compilées dans le JS).
python3 - <<'PY'
import json, os, pathlib
pathlib.Path(".dart_defines.json").write_text(json.dumps({
    "SUPABASE_URL": os.environ.get("SUPABASE_URL", ""),
    "SUPABASE_ANON_KEY": os.environ.get("SUPABASE_ANON_KEY", ""),
    "WEB_APP_URL": os.environ.get("WEB_APP_URL")
        or os.environ.get("DEPLOY_PRIME_URL")
        or os.environ.get("URL")
        or "",
    "APP_ENV": os.environ.get("APP_ENV", "prod"),
}))
PY

FLUTTER_DIR="${FLUTTER_ROOT:-$ROOT/.flutter-sdk}"
if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  echo "==> Cloning Flutter SDK (stable)"
  rm -rf "$FLUTTER_DIR"
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"
# Netlify tourne en utilisateur non privilégié : le SDK doit être inscriptible.
git config --global --add safe.directory "$FLUTTER_DIR" || true

flutter --version
flutter config --no-analytics --enable-web
flutter pub get
flutter build web --release --base-href / -t lib/web_intake_main.dart \
  --dart-define-from-file=.dart_defines.json
rm -f .dart_defines.json

echo "==> Web build ready in build/web"
