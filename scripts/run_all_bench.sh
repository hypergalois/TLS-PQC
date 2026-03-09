#!/bin/bash
set -euo pipefail

ROOT="$HOME/tls-pqc-lab"
BIN="$ROOT/bench/tls_bench_client"
RESULTS="$ROOT/results"

mkdir -p "$RESULTS"

run_case() {
  local name="$1"
  local server_script="$2"
  local groups="$3"
  local cafile="$4"
  local sni="$5"
  local runs="$6"

  echo ">>> [${name}] Lanzando servidor: ${server_script}"
  "$ROOT/scripts/${server_script}" >"$RESULTS/server_${name}.log" 2>&1 &
  local spid=$!

  sleep 1

  echo ">>> [${name}] Ejecutando cliente (${runs} handshakes)..."
  "$BIN" localhost 4433 "$groups" "$ROOT/certs/${cafile}" "$sni" "$runs" \
    > "$RESULTS/bench_${name}.csv"

  echo ">>> [${name}] Terminando servidor (PID=${spid})"
  kill "$spid" 2>/dev/null || true
  wait "$spid" 2>/dev/null || true

  sleep 1

  echo ">>> [${name}] OK: resultados en $RESULTS/bench_${name}.csv"
  echo
}

RUNS=5000

run_case "c1_classic"              "run_server_c1_classic.sh"              "X25519"          "ca_classic.crt" "classic.server" "$RUNS"
run_case "c2_hybrid_classiccert"   "run_server_c2_hybrid_classiccert.sh"   "X25519MLKEM768"  "ca_classic.crt" "classic.server" "$RUNS"
run_case "c3_classic_pqcert"       "run_server_c3_classic_pqcert.sh"       "X25519"          "ca_pqc.crt"     "pqc.server"     "$RUNS"
run_case "c4_hybrid_pqcert"        "run_server_c4_hybrid_pqcert.sh"        "X25519MLKEM768"  "ca_pqc.crt"     "pqc.server"     "$RUNS"

echo ">>> Todas finished."
