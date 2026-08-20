#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/.build/EdgeTodo.app"
INSTALL="/Applications/EdgeTodo.app"

"$ROOT/Scripts/build.sh"

# Prefer a lasting install so login items survive reboot.
pkill -x EdgeTodo 2>/dev/null || true
rm -rf "$INSTALL"
cp -R "$APP" "$INSTALL"
open "$INSTALL"

echo "Installed and launched $INSTALL"
