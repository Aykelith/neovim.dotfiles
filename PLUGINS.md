# PLUGINS

| Plugin name | Repository | File path | Commit/Version | Description |
|---|---|---|---|---|
| lazy.nvim | [folke/lazy.nvim](https://github.com/folke/lazy.nvim) | `init.lua` | lazy-lock.json | Plugin manager (bootstrapped) |
| nvim-lspconfig | [neovim/nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | `lua/plugins/lsp.lua` | lazy-lock.json | LSP server configs for native `vim.lsp.enable` |
| mason.nvim | [mason-org/mason.nvim](https://github.com/mason-org/mason.nvim) | `lua/plugins/lsp.lua` | lazy-lock.json | Installs LSP servers (lua_ls, gopls, ts_ls) |
| mason-lspconfig.nvim | [mason-org/mason-lspconfig.nvim](https://github.com/mason-org/mason-lspconfig.nvim) | `lua/plugins/lsp.lua` | lazy-lock.json | Bridges Mason ↔ lspconfig |
| trouble.nvim | [folke/trouble.nvim](https://github.com/folke/trouble.nvim) | `lua/plugins/trouble.lua` | lazy-lock.json | Diagnostics/quickfix/LSP list UI |
| which-key.nvim | [folke/which-key.nvim](https://github.com/folke/which-key.nvim) | `lua/plugins/which-key.lua` | lazy-lock.json | Keybinding popup |
| snacks.nvim | [folke/snacks.nvim](https://github.com/folke/snacks.nvim) | `lua/plugins/snacks.lua` | lazy-lock.json | QoL collection (notifier, bigfile, etc.) |
| nvim-web-devicons | [nvim-tree/nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) | `lua/plugins/icons.lua` | lazy-lock.json | NerdFont glyphs |
| catppuccin | [catppuccin/nvim](https://github.com/catppuccin/nvim) | `lua/plugins/catppuccin.lua` | lazy-lock.json | Colorscheme (mocha), loaded eagerly at startup |
| ~~nvim-treesitter~~ | ~~[nvim-treesitter/nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)~~ | `lua/config/treesitter.lua` | removed | **Removed.** master branch archived; queries conflicted with nvim 0.12.3 bundled parsers. Built-in treesitter used instead via FileType autocmd. |
| lualine.nvim | [nvim-lualine/lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) | `lua/plugins/lualine.lua` | lazy-lock.json | Statusline (lazy: VeryLazy) |
| blink.cmp | [saghen/blink.cmp](https://github.com/saghen/blink.cmp) | `lua/plugins/completion.lua` | lazy-lock.json | Completion engine; LSP capabilities wired in `lsp.lua` |
| telescope.nvim | [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | `lua/plugins/telescope.lua` | lazy-lock.json | Fuzzy finder (lazy: cmd/keys) |
| telescope-fzf-native.nvim | [nvim-telescope/telescope-fzf-native.nvim](https://github.com/nvim-telescope/telescope-fzf-native.nvim) | `lua/plugins/telescope.lua` | lazy-lock.json | Compiled fzf sorter for telescope |
| plenary.nvim | [nvim-lua/plenary.nvim](https://github.com/nvim-lua/plenary.nvim) | `lua/plugins/telescope.lua` | lazy-lock.json | Lua util lib (telescope dep) |
| gitsigns.nvim | [lewis6991/gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | `lua/plugins/gitsigns.lua` | lazy-lock.json | Git gutter signs + hunk nav (lazy: BufReadPre) |
| conform.nvim | [stevearc/conform.nvim](https://github.com/stevearc/conform.nvim) | `lua/plugins/conform.lua` | lazy-lock.json | Formatter dispatch + format-on-save |
| flash.nvim | [folke/flash.nvim](https://github.com/folke/flash.nvim) | `lua/plugins/flash.lua` | lazy-lock.json | Jump motions (lazy: keys) |
| minuet-ai.nvim | [milanglacier/minuet-ai.nvim](https://github.com/milanglacier/minuet-ai.nvim) | `lua/plugins/minuet.lua` | v0.9.0 | Local LLM autocomplete (ghost text) via self-hosted Ollama / Qwen2.5-Coder (lazy: InsertEnter) |
| bufferline.nvim | [akinsho/bufferline.nvim](https://github.com/akinsho/bufferline.nvim) | `lua/plugins/bufferline.lua` | lazy-lock.json | VSCode-style bufferline showing all open buffers as tabs (lazy: VeryLazy) |

## Observations

### minuet-ai.nvim — error notifications gated on the local-autocomplete service

`config()` in `lua/plugins/minuet.lua` wraps `require("minuet.utils").notify` and
routes warn/error notifications through `lua/methods/minuet_error_gate.lua`.

**Why:** when the `local-autocomplete` systemd service is stopped, every failed
completion otherwise spams an unreachable/timeout error. The gate probes
`systemctl is-active local-autocomplete` (async) on the first failure: if the
service is down it prompts the user to start it once, then swallows further errors
(re-probing at most every 30s). If the service is up but requests still fail,
errors pass through unchanged. The gate core is dependency-injected (check/prompt/
now) so it's unit-tested without systemd — see `tests/e2e_spec.lua` ("error gate:" tests).

### nvim-treesitter — removed (2026-06-26)

Plugin removed; `lua/config/treesitter.lua` replaces it with a single `FileType` autocmd calling `vim.treesitter.start()`.

**Why:** nvim-treesitter `master` branch was archived. Its bundled highlight queries referenced node types (e.g. `underscore` in gdscript) that don't exist in the parser binaries, causing `E5108` errors on every file open. nvim 0.12.3 bundles 37 parsers (lua, go, rust, typescript, gdscript, etc.) with matching queries; the plugin was redundant and broken.

**Trade-off:** No `:TSInstall`/`:TSUpdate` commands. Indent is nvim built-in (no treesitter-indent module). For languages not bundled with nvim, no parser auto-install.

### snacks.nvim — scope treesitter injections disabled

`scope.treesitter.injections` set to `false` in `lua/plugins/snacks.lua`.

**Why:** nvim 0.12.3 has a bug in async treesitter parsing with injection queries. When opening a markdown file, snacks scope triggered an async parse with injections enabled (the default). During injection query evaluation, `vim.treesitter.get_range(node)` was called with a nil `TSNode`, crashing with `E5108: attempt to call method 'range' (a nil value)`. Disabling injections stops snacks from passing `range=true` to the async parser, avoiding the nil node path. Injections are only meaningful for multi-language files (Vue, JSX templates); Go/Lua/Rust/TS are unaffected.
