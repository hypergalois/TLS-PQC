#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

OQS_ROOT="$ROOT/oqs-provider"
OPENSSL_BIN="$OQS_ROOT/.local/bin/openssl"

if [[ ! -x "$OPENSSL_BIN" ]]; then
  echo "ERROR: no encuentro openssl OQS en: $OPENSSL_BIN" >&2
  exit 1
fi

cd "$ROOT"

exec "$OPENSSL_BIN" s_server \
  -provider default -provider oqsprovider \
  -accept 4433 \
  -cert certs/server_classic.crt \
  -key  certs/server_classic.key \
  -CAfile certs/ca_classic.crt \
  -verify 1 \
  -tls1_3 \
  -groups X25519 \
  -quiet
