# Edge Todo

MVP sidebar for macOS: a thin strip on the **right edge** of your screen. Hover to expand a quick personal to-do list. Collapse when the cursor leaves.

## How it works

| Piece | Approach |
| --- | --- |
| Always visible strip | Borderless `NSPanel` at floating window level |
| Hover expand | Global + local mouse monitors near the right edge |
| UI | SwiftUI list + text field |
| Persistence | `~/Library/Application Support/EdgeTodo/todos.json` |
| Dock | Hidden (`LSUIElement`) — lives in the menu bar |

This is the native-Mac approach (same family as SideNotes-style edge panels). Electron/Tauri could do a similar always-on-top window, but Swift is lighter and fits the OS better for an accessory panel.

## Requirements

- macOS 14+
- Xcode Command Line Tools / Swift toolchain

## Run

```bash
./Scripts/run.sh
```

Or build only:

```bash
./Scripts/build.sh
open .build/EdgeTodo.app
```

## Use

1. Look for the teal handle on the right edge of the screen.
2. Move the cursor onto it — the panel slides open.
3. Type a todo and press Enter.
4. Click the circle to complete, × to delete.
5. Menu bar → **Edge Todo** → Quit when done.

## MVP scope

- Add / complete / delete todos
- Clear completed
- Hover expand / auto-collapse
- Survive app restarts via JSON on disk

## Later ideas

- Hotkey to peek open
- Multiple lists
- Drag todos
- Launch at login
- Left-edge option / multi-monitor pick
