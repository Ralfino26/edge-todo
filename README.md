# Edge Todo

A minimal macOS edge drawer for quick todos.

![Edge Todo demo](assets/demo.gif)

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

For a stable login item, copy the app somewhere lasting (recommended):

```bash
./Scripts/build.sh
cp -R .build/EdgeTodo.app /Applications/
open /Applications/EdgeTodo.app
```

## Use

1. Move your cursor to the right edge of the screen
2. Type a task and press Enter
3. Click the circle to complete, × to delete
4. Menu bar → **Edge Todo** → Quit

### Open at Login

On first launch, Edge Todo registers itself to start when you log in. Toggle it anytime via menu bar → **Open at Login**.

macOS may ask for permission under **System Settings → General → Login Items**.

## Data

Todos are stored at `~/Library/Application Support/EdgeTodo/todos.json`.

## Stack

Native Swift + SwiftUI + AppKit (`NSPanel`). No Electron, no dependencies.

## License

MIT
