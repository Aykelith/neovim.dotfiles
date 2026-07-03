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
| grug-far.nvim | [MagicDuck/grug-far.nvim](https://github.com/MagicDuck/grug-far.nvim) | `lua/plugins/grug-far.lua` | lazy-lock.json | Multi-file search & replace with diff preview, ripgrep-backed (lazy: cmd/keys) |

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

### nvim-lspconfig — `LspInfo`/`LspStart`/`LspRestart`/`LspStop` do not exist on this Nvim (2026-07-03)

No config change; documenting expected behavior so it isn't "fixed" again by
mistake.

**Why:** Nvim 0.11+ ships a native `:lsp` command (`:lsp enable|disable|restart|stop`,
see `:help :lsp`). `nvim-lspconfig`'s `plugin/lspconfig.lua` detects this
(`vim.fn.exists(':lsp') == 2`) and returns before defining any of its legacy
`LspInfo`/`LspLog`/`LspStart`/`LspRestart`/`LspStop` commands, deferring to the
native one entirely. A prior attempt to force these into existence by adding
them as `cmd` lazy-load triggers in `lua/plugins/lsp.lua` didn't work: lazy.nvim's
`cmd` stub is deleted the first time the command is invoked (or immediately
once the plugin loads via the `event` trigger), and since the real definition
is always skipped by the guard above, the command ends up not existing at all
afterward — worse than before, since the pending stub had briefly made
`exists(':LspRestart')` return true. Use the native commands instead:
`:lsp restart [client]`, `:lsp stop [client]`, `:lsp enable|disable
[config_name]`, `:checkhealth vim.lsp` for status, and
`:lua vim.cmd('tabnew '..vim.lsp.log.get_filename())` for the log.

### telescope.nvim — live_grep forced case-insensitive (2026-07-03)

`opts.pickers.live_grep.additional_args` adds `--ignore-case` to the ripgrep
invocation in `lua/plugins/telescope.lua`.

**Why:** telescope's default `vimgrep_arguments` use `--smart-case`, which
switches to case-sensitive matching as soon as the query contains an
uppercase letter. The user wants Live Grep to always ignore case regardless
of query casing.

### telescope.nvim — search dot-directories, keep .gitignore/.ignore respected (2026-07-03)

`pickers.live_grep.additional_args` also adds `--hidden`, and
`pickers.find_files.hidden = true` is set, in `lua/plugins/telescope.lua`.

**Why:** by default ripgrep/fd skip dot-files and dot-directories. `--hidden`
makes them searchable/findable. This does not disable `.gitignore`/`.ignore`
respect (that's ripgrep's separate default, unaffected by `--hidden`) — a
project-root `.ignore` file (ripgrep-native, same syntax as `.gitignore`) is
the supported way to add extra excludes beyond git's own.

### conform.nvim — markdown/mdx prettier warn-once (2026-06-28)

`format_on_save` is a function; for markdown/mdx it calls
`lua/methods/markdown-prettier-warn.lua` before returning format options.

**Why:** prettier must come from each project's `node_modules` (not global
PATH). If it's absent, conform silently skips formatting with no feedback.
The warn module fires `vim.notify(WARN)` once per session when
`get_formatter_info("prettier", bufnr).available` is false, then stays
silent. Dependency-injected (check_fn, notify_fn) so unit-tested in
`tests/e2e_spec.lua` ("markdown prettier warn:" tests).

### nvim-treesitter — removed (2026-06-26)

Plugin removed; `lua/config/treesitter.lua` replaces it with a single `FileType` autocmd calling `vim.treesitter.start()`.

**Why:** nvim-treesitter `master` branch was archived. Its bundled highlight queries referenced node types (e.g. `underscore` in gdscript) that don't exist in the parser binaries, causing `E5108` errors on every file open. nvim 0.12.3 bundles 37 parsers (lua, go, rust, typescript, gdscript, etc.) with matching queries; the plugin was redundant and broken.

**Trade-off:** No `:TSInstall`/`:TSUpdate` commands. Indent is nvim built-in (no treesitter-indent module). For languages not bundled with nvim, no parser auto-install.

### snacks.nvim — scope treesitter injections disabled

`scope.treesitter.injections` set to `false` in `lua/plugins/snacks.lua`.

**Why:** nvim 0.12.3 has a bug in async treesitter parsing with injection queries. When opening a markdown file, snacks scope triggered an async parse with injections enabled (the default). During injection query evaluation, `vim.treesitter.get_range(node)` was called with a nil `TSNode`, crashing with `E5108: attempt to call method 'range' (a nil value)`. Disabling injections stops snacks from passing `range=true` to the async parser, avoiding the nil node path. Injections are only meaningful for multi-language files (Vue, JSX templates); Go/Lua/Rust/TS are unaffected.
