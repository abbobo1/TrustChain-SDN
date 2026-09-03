#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "Checking Python source..."
python3 -m compileall -q blockchain-api sdn-controller tests

echo "Checking shell scripts..."
bash -n blockchain-api/read_policy.sh \
    benchmark_throughput.sh benchmark_write_latency.sh

if [[ -x .venv/bin/pytest ]]; then
    echo "Running automated tests..."
    .venv/bin/pytest -q
else
    echo "Skipping pytest: run 'make install' first."
fi

if command -v go >/dev/null 2>&1; then
    echo "Checking Go chaincode..."
    (cd trustchain-smartcontract && go test ./...)
else
    echo "Skipping Go check: Go is not installed."
fi

echo "Preflight checks completed."
