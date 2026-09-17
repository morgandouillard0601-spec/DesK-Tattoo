#!/usr/bin/env bash
# Génère le QR d'accueil d'un compte : {WEB_APP_URL}/intake/{token}
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/tools/intake-qr"
if [ ! -d node_modules/@liquid-js/qr-code-styling-cli ]; then
  npm i @liquid-js/qr-code-styling-cli
fi
exec node generate.mjs "$@"
