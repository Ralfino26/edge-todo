#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/.build"
APP_DIR="$BUILD_DIR/EdgeTodo.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
SOURCES=(
  "$ROOT/Sources/TodoItem.swift"
  "$ROOT/Sources/TodoStore.swift"
  "$ROOT/Sources/LaunchAtLogin.swift"
  "$ROOT/Sources/TodoPanelView.swift"
  "$ROOT/Sources/EdgePanelController.swift"
  "$ROOT/Sources/EdgeTodoApp.swift"
)

mkdir -p "$MACOS"
swiftc -O -whole-module-optimization \
  -target arm64-apple-macos14.0 \
  -sdk "$(xcrun --show-sdk-path)" \
  -framework SwiftUI \
  -framework AppKit \
  -framework QuartzCore \
  -framework ServiceManagement \
  -o "$MACOS/EdgeTodo" \
  "${SOURCES[@]}"

cp "$ROOT/Info.plist" "$CONTENTS/Info.plist"
echo "Built $APP_DIR"
