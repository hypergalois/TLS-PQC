#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$ROOT/bench/tls_bench_client"
RESULTS="$ROOT/results"

if [[ ! -x "$BIN" ]]; then
  echo "ERROR: no encuentro el binario de cliente en: $BIN" >&2
  exit 1
fi

mkdir -p "$RESULTS"

CPU_EVENTS="task-clock,cycles,instructions,branches,branch-misses,cache-references,cache-misses"

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

  echo ">>> [${name}] Ejecutando cliente (${runs} handshakes) con perf..."
  perf stat -x, \
    -e "$CPU_EVENTS" \
    -o "$RESULTS/perf_${name}.csv" \
    "$BIN" localhost 4433 "$groups" "$ROOT/certs/${cafile}" "$sni" "$runs" \
      > "$RESULTS/bench_${name}.csv"

  echo ">>> [${name}] Terminando servidor (PID=${spid})"
  kill "$spid" 2>/dev/null || true
  wait "$spid" 2>/dev/null || true

  sleep 1

  echo ">>> [${name}] OK: bench en $RESULTS/bench_${name}.csv"
  echo ">>> [${name}] OK: perf  en $RESULTS/perf_${name}.csv"
  echo
}

RUNS=100000

run_case "c1_classic"              "run_server_c1_classic_perf.sh"              "X25519"         "ca_classic.crt" "classic.server" "$RUNS"
run_case "c2_hybrid_classiccert"   "run_server_c2_hybrid_classiccert_perf.sh"   "X25519MLKEM768" "ca_classic.crt" "classic.server" "$RUNS"
run_case "c3_classic_pqcert"       "run_server_c3_classic_pqcert_perf.sh"       "X25519"         "ca_pqc.crt"     "pqc.server"     "$RUNS"
run_case "c4_hybrid_pqcert"        "run_server_c4_hybrid_pqcert_perf.sh"        "X25519MLKEM768" "ca_pqc.crt"     "pqc.server"     "$RUNS"

echo ">>> Todo finished."
