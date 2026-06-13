#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="${REPO_ROOT}/bin"

if [ -f "${BIN_DIR}/htmltest" ]; then
    echo "htmltest is already installed in ./bin/htmltest"
    exit 0
fi

echo "Installing htmltest..."
mkdir -p "${BIN_DIR}"
curl -sL https://htmltest.wjdp.uk | sh -s -- -b "${BIN_DIR}"
echo "htmltest installed successfully."
