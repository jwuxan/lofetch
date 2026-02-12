#!/usr/bin/env bash
# install.sh — install zfetch to your system
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ ! -f "$SCRIPT_DIR/zfetch" ]]; then
    echo "Error: zfetch not found in $SCRIPT_DIR" >&2
    exit 1
fi

echo "Installing zfetch to $INSTALL_DIR/zfetch..."
install -m 755 "$SCRIPT_DIR/zfetch" "$INSTALL_DIR/zfetch"
echo "Done. Run 'zfetch' to get started."
