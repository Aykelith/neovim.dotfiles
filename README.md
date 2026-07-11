# nvim config

Personal Neovim configuration. See [AGENT.md](AGENT.md) for structure.

## Godot 4 as external editor

Inspired by [Simon Dalvai's guide](https://simondalvai.org/blog/godot-neovim/).

Neovim listens on a per-project pipe so Godot can send it files and cursor
positions. Config: [`lua/config/godot-server.lua`](lua/config/godot-server.lua).

### Start the server

1. `cd` into your Godot project (the dir containing `project.godot`).
2. Run `nvim`. It auto-starts a server on `{project}/server.pipe` when opened
   inside a Godot project (searches up to 4 dirs up for `project.godot`).
3. Verify with `:echo v:servername` or `:lua print(vim.fn.serverlist())`.

### Godot settings

**Editor Settings > Text Editor > External:**

- Enable **Use External Editor**
- **Exec Path:** the wrapper script
  ```
  /home/alexxanderx/.config/nvim/scripts/godot-open.sh
  ```
- **Exec Flags:**
  ```
  {project} {file} {line} {col}
  ```

Optional: under the Script view enable **Debug with External Editor** so
Godot's internal editor stays closed while debugging.

### What the wrapper does (X11 + Alacritty)

[`scripts/godot-open.sh`](scripts/godot-open.sh):

1. **Server down / stale pipe** → removes any stale pipe and opens a fresh
   Alacritty (WM_CLASS `godot-nvim`) running nvim in the project dir, which
   autostarts the server.
2. **Server up** → sends the file + cursor to the running nvim, then raises that
   window by its `godot-nvim` WM_CLASS (`wmctrl -x -a godot-nvim`) — stable even
   as nvim changes the title — falling back to the title, then any Alacritty.

Requires `wmctrl` and `alacritty`. Different terminal? Change the two spots in
the script: the launch command and the `wmctrl` title/class match.

**Inside tmux:** when the server starts, nvim records its `$TMUX_PANE` at
`{project}/server.pipe.tmux` (removed on exit). The wrapper reads it and runs
`tmux switch-client` / `select-window` / `select-pane` so the right tmux
window/pane is focused before the terminal is raised. Assumes tmux's default
socket — add `-L <name>` to the `tmux` calls in the script if you use a named one.

### Code intelligence (LSP)

GDScript's language server lives inside the running Godot editor, not Mason.
nvim connects to it over TCP (`127.0.0.1:6005`) — config in
[`lua/plugins/lsp.lua`](lua/plugins/lsp.lua). Diagnostics, completion, `gd`,
`K`, etc. work on `.gd` buffers whenever Godot is open on the project.

Godot side (once): **Editor Settings > Network > Language Server** — port
`6005` (default). If yours differs, set `GDScript_Port` in nvim's environment.
No live LSP if Godot isn't running — the editor *is* the server.

### Debugging (breakpoints)

`nvim-dap` ([`lua/plugins/dap.lua`](lua/plugins/dap.lua)) connects to Godot 4's
built-in debug adapter, so breakpoints set in nvim are real — Godot stops on
them. Loads automatically on any `.gd` (gdscript) buffer.

Godot side (once):

1. **Debug > Debug with External Editor** — on.
2. **Editor Settings > Network > Debug Adapter** — port `6006` (default).
3. Keep the Godot editor running (it *is* the adapter).

Keys (normal mode):

| Key | Action |
|---|---|
| `<leader>db` | Toggle breakpoint (red ● in the gutter) |
| `<leader>dc` | Continue / start debugging |
| `<leader>do` | Step over |
| `<leader>di` | Step into |
| `<leader>dO` | Step out |
| `<leader>dt` | Terminate |

Flow: open a `.gd` file → `<leader>db` on a line → `<leader>dc` to launch the
scene → execution stops at the breakpoint (marked `▶`).

### Troubleshooting

- Wrong window focused among several Alacritty windows: give Godot's nvim its
  own window so the `godot-nvim` title match hits it.
- A stale `server.pipe` after a crash is now cleared automatically on the next
  open (the wrapper `rm`s it before launching a fresh terminal).

Based on [Simon Dalvai's guide](https://simondalvai.org/blog/godot-neovim/).
