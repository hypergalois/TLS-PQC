#!/usr/bin/env python3
import argparse
import csv
import subprocess
import sys
import time
from pathlib import Path

BASE = Path.home() / "tls-pqc-lab"
OPENSSL_BIN = BASE / "oqs-provider" / ".local" / "bin" / "openssl"
CERTS_DIR = BASE / "certs"
RESULTS_DIR = BASE / "results"

CONFIGS = {
    "c1_classic": {
        "description": "TLS 1.3, X25519, certificado clásico ECDSA",
        "groups": "X25519",
        "cafile": CERTS_DIR / "ca_classic.crt",
        "servername": "classic.server",
    },
    "c2_hybrid_classiccert": {
        "description": "TLS 1.3, X25519MLKEM768, certificado clásico ECDSA",
        "groups": "X25519MLKEM768",
        "cafile": CERTS_DIR / "ca_classic.crt",
        "servername": "classic.server",
    },
    "c3_classic_pqcert": {
        "description": "TLS 1.3, X25519, certificado PQ (mldsa65)",
        "groups": "X25519",
        "cafile": CERTS_DIR / "ca_pqc.crt",
        "servername": "pqc.server",
    },
    "c4_hybrid_pqcert": {
        "description": "TLS 1.3, X25519MLKEM768, certificado PQ (mldsa65)",
        "groups": "X25519MLKEM768",
        "cafile": CERTS_DIR / "ca_pqc.crt",
        "servername": "pqc.server",
    },
}


def run_one(config_name: str, run_id: int, timeout: float):
    cfg = CONFIGS[config_name]

    cmd = [
        str(OPENSSL_BIN),
        "s_client",
        "-provider", "default",
        "-provider", "oqsprovider",
        "-connect", "localhost:4433",
        "-groups", cfg["groups"],
        "-CAfile", str(cfg["cafile"]),
        "-servername", cfg["servername"],
        "-tls1_3",
    ]

    start = time.perf_counter()
    try:
        proc = subprocess.run(
            cmd,
            input=b"",
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=timeout,
        )
        elapsed_ms = (time.perf_counter() - start) * 1000.0
        rc = proc.returncode
        out = proc.stdout.decode("utf-8", errors="replace")
    except subprocess.TimeoutExpired as e:
        elapsed_ms = timeout * 1000.0
        rc = 124
        out_bytes = b""
        if getattr(e, "output", None):
            out_bytes += e.output
        if getattr(e, "stderr", None):
            out_bytes += e.stderr
        out = out_bytes.decode("utf-8", errors="replace")

    success = int(rc == 0)

    # Métrica adicional
    bytes_read = -1
    bytes_written = -1
    for line in out.splitlines():
        line = line.strip()
        if line.startswith("SSL handshake has read"):
            parts = line.split()
            try:
                idx_read = parts.index("read") + 1
                idx_written = parts.index("written") + 1
                bytes_read = int(parts[idx_read])
                bytes_written = int(parts[idx_written])
            except Exception:
                pass
            break

    return {
        "run_id": run_id,
        "elapsed_ms": f"{elapsed_ms:.3f}",
        "success": success,
        "returncode": rc,
        "bytes_read": bytes_read,
        "bytes_written": bytes_written,
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True, choices=CONFIGS.keys())
    parser.add_argument("--runs", type=int, default=10)
    parser.add_argument("--timeout", type=float, default=5.0)
    args = parser.parse_args()

    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    out_file = RESULTS_DIR / f"metrics_{args.config}.csv"

    with out_file.open("w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(
            ["run_id", "elapsed_ms", "success", "returncode", "bytes_read", "bytes_written"]
        )

        ok = 0
        for i in range(1, args.runs + 1):
            row = run_one(args.config, i, args.timeout)
            writer.writerow(
                [
                    row["run_id"],
                    row["elapsed_ms"],
                    row["success"],
                    row["returncode"],
                    row["bytes_read"],
                    row["bytes_written"],
                ]
            )
            if row["success"]:
                ok += 1
            print(
                f"{args.config}: {i}/{args.runs} handshakes (ok={ok})",
                file=sys.stderr,
                end="\r",
                flush=True,
            )

    print(f"\n[INFO] Resultado escrito en {out_file} ({ok}/{args.runs} handshakes correctos)")


if __name__ == "__main__":
    main()
