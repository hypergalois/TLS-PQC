#!/bin/bash
set -euo pipefail

OQS_ROOT="$HOME/tls-pqc-lab/oqs-provider"
OPENSSL_BIN="$OQS_ROOT/.local/bin/openssl"

cd "$HOME/tls-pqc-lab"

exec "$OPENSSL_BIN" s_server \
  -provider default -provider oqsprovider \
  -accept 4433 \
  -cert certs/server_pqc.crt \
  -key  certs/server_pqc.key \
  -CAfile certs/ca_pqc.crt \
  -verify 1 \
  -tls1_3 \
  -groups X25519 \
  -quiet
