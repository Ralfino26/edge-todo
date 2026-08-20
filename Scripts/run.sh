#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/.build/EdgeTodo.app"

"$ROOT/Scripts/build.sh"
pkill -x EdgeTodo 2>/dev/null || true
open "$APP"
echo "Launched EdgeTodo (menu bar + right-edge strip)"
