# Edge Todo

A minimal macOS edge drawer for quick todos.

Hover the **right edge** of your screen — a dark glass panel slides in. Add tasks, check them off, move on. It lives in the menu bar (no Dock icon) and saves to disk automatically.

## Requirements

- macOS 14+
- Xcode Command Line Tools (`xcode-select --install`)

## Run

```bash
./Scripts/run.sh
```

Build only:

```bash
./Scripts/build.sh
open .build/EdgeTodo.app
```

## Use

1. Move your cursor to the right edge of the screen
2. Type a task and press Enter
3. Click the circle to complete, × to delete
4. Menu bar → **Edge Todo** → Quit

Todos are stored at `~/Library/Application Support/EdgeTodo/todos.json`.

## Stack

Native Swift + SwiftUI + AppKit (`NSPanel`). No Electron, no dependencies.

## License

MIT
