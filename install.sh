#!/usr/bin/env bash
# install.sh — install lofetch to your system
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ ! -f "$SCRIPT_DIR/lofetch" ]]; then
    echo "Error: lofetch not found in $SCRIPT_DIR" >&2
    exit 1
fi

echo "Installing lofetch to $INSTALL_DIR/lofetch..."
install -m 755 "$SCRIPT_DIR/lofetch" "$INSTALL_DIR/lofetch"
echo "Done. Run 'lofetch' to get started."
