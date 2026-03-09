# TLS 1.3 Hybrid Benchmarks with OpenSSL and OQS Provider

#### Author: José Luis Delgado Jiménez

Four scenarios are evaluated: classical KEM with classical certificates, hybrid KEM with classical certificates, classical KEM with PQC certificates, and hybrid KEM with PQC certificates.

A custom TLS client written in C drives the experiments, while small wrapper scripts start the corresponding openssl s_server instances.

# Repository structure

bench/  
Contains the TLS benchmarking client and its build configuration.

certs/  
Stores the CA and server certificates used in the experiments, including both classical and PQC variants.

oqs-provider/  
Contains the local installation of OpenSSL 3 with the OQS provider enabled.

results/  
All benchmark CSV files and server logs are written here.

scripts/  
Wrapper scripts used to launch the servers and run the benchmark campaigns.

# Building the benchmark client

The TLS client used for the measurements is located at bench/tls_bench_client.c. It creates a fresh TCP connection for each run, performs a TLS 1.3 handshake, and records timing and byte counters.

To build it:

`gcc -O2 -Wall
 -Ioqs-provider/.local/include
 bench/tls_bench_client.c -o bench/tls_bench_client
 -Loqs-provider/.local/lib64
 -Wl,-rpath,"$PWD/oqs-provider/.local/lib64"
 -lssl -lcrypto`

# Benchmark client usage

The client takes six positional arguments:

tls_bench_client host port groups cafile sni runs

Example:

bench/tls_bench_client localhost 4433 X25519 certs/ca_classic.crt classic.server 50

# Running the benchmarks

The repository includes scripts to start the correct server configuration and execute the experiments automatically.

To run all latency benchmarks:

./scripts/run_all_bench.sh

This launches each scenario sequentially, executes N handshakes, and writes the results to the results directory.

# Benchmarks with CPU measurements

To collect CPU counters using perf, run:

sudo ./scripts/run_all_bench_with_perf.sh
