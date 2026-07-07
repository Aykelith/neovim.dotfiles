# PLUGINS

| Plugin name | Repository | File path | Commit/Version | Description |
|---|---|---|---|---|
| lazy.nvim | [folke/lazy.nvim](https://github.com/folke/lazy.nvim) | `init.lua` | lazy-lock.json | Plugin manager (bootstrapped) |
| nvim-lspconfig | [neovim/nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | `lua/plugins/lsp.lua` | lazy-lock.json | LSP server configs for native `vim.lsp.enable` |
| mason.nvim | [mason-org/mason.nvim](https://github.com/mason-org/mason.nvim) | `lua/plugins/lsp.lua` | lazy-lock.json | Installs LSP servers (lua_ls, gopls, ts_ls, intelephense) |
| mason-lspconfig.nvim | [mason-org/mason-lspconfig.nvim](https://github.com/mason-org/mason-lspconfig.nvim) | `lua/plugins/lsp.lua` | lazy-lock.json | Bridges Mason ↔ lspconfig |
| trouble.nvim | [folke/trouble.nvim](https://github.com/folke/trouble.nvim) | `lua/plugins/trouble.lua` | lazy-lock.json | Diagnostics/quickfix/LSP list UI |
| which-key.nvim | [folke/which-key.nvim](https://github.com/folke/which-key.nvim) | `lua/plugins/which-key.lua` | lazy-lock.json | Keybinding popup |
| snacks.nvim | [folke/snacks.nvim](https://github.com/folke/snacks.nvim) | `lua/plugins/snacks.lua` | lazy-lock.json | QoL collection (notifier, bigfile, etc.) |
| nvim-web-devicons | [nvim-tree/nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) | `lua/plugins/icons.lua` | lazy-lock.json | NerdFont glyphs |
| catppuccin | [catppuccin/nvim](https://github.com/catppuccin/nvim) | `lua/plugins/catppuccin.lua` | lazy-lock.json | Colorscheme (mocha), loaded eagerly at startup |
| nvim-treesitter | [nvim-treesitter/nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) (branch `main`) | `lua/plugins/treesitter.lua` | `4916d6592ede8c07973490d9322f187e07dfefac` | Installs parsers + matching query files only; highlighting itself is native, started by `lua/config/treesitter.lua`'s FileType autocmd |
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

### telescope.nvim — live grep + find files include/exclude path filters (2026-07-07)

`<leader>fg` (Live Grep) and `<leader>ff` (Find Files) both open through
`make_filterable_opener(display_name, builtin_name, build_picker_opts)` in
`lua/plugins/telescope.lua` — a factory (not `:Telescope live_grep`/
`:Telescope find_files` directly) shared by both pickers, since the
filter/persistence/help behavior below is identical for both; only how a
picker turns `exclude_dirs` into picker opts differs
(`build_picker_opts`). `open_live_grep`/`open_find_files` are each one call
to that factory.

Inside either picker's prompt:
- `<C-o>` asks (via `vim.fn.input`) for comma-separated paths to restrict
  the search to (`search_dirs`, natively supported by both pickers).
- `<C-e>` asks for comma-separated paths to exclude. Live Grep turns these
  into `--glob=!path` via the native `glob_pattern` opt. `find_files` has
  no equivalent native opt, so exclusion is done via a custom
  `find_command` (`find_files_exclude_command`) that hardcodes ripgrep
  (`rg --files --glob=!path ...`) — matching the ripgrep-only glob support
  Live Grep already relies on. `hidden`/`search_dirs` etc. still get
  applied on top by Telescope's own `find_files`, since that logic runs
  after `opts.find_command` regardless of where the command list came
  from.
- Either key re-opens the picker with the updated filters, carrying over
  the current query text.
- `<C-g>` clears the query text and both filters and reopens fresh.

The active filters are shown in the prompt window's border title
(`Live Grep [... | in: ... | not in: ...]`) — read-only, since it's a
border title rather than an editable field. The title also permanently
shows `?: <C-/>`: Telescope already binds `<C-/>` (insert
mode) / `?` (normal mode) to `actions.which_key`, a popup listing the
current picker's keymaps — binding literal `?` directly was rejected since
it would swallow `?` typed into a search query. The `<C-o>`/`<C-e>`/`<C-g>`
mappings were given explicit `desc`s (e.g. `"Live Grep: only in paths"`,
kept under ~30 chars so which-key's `name_width` column doesn't truncate
them) so they show up there with a readable name instead of Telescope's
best-effort anonymous-function name.

Each picker keeps its own `last_search` table (query text + both filters),
closed over per `make_filterable_opener` call, remembering across separate
`<leader>fg`/`<leader>ff` presses (not just across `<C-o>`/`<C-e>`/`<C-g>`
re-opens within one session): a buffer-local `TextChangedI`/`TextChanged`
autocmd on the prompt keeps `last_search.text` current on every keystroke
(so it survives however the picker closes — Esc, selecting a result,
`<C-o>`/`<C-e>`/`<C-g>`...), and the picker re-opens with
`last_search.include_dirs/exclude_dirs/text` instead of empty values. The
prompt buffer's line includes the literal `prompt_prefix` (e.g. `"> "`), so
it's stripped the same way Telescope's own `Picker:_get_prompt()` does
before being stored.

**Why:** the user wanted to scope/exclude both live grep and find-files
results by path without retyping ripgrep flags; wanted visible confirmation
of which paths were applied; wanted a discoverable way to find the
shortcuts without memorizing them; wanted a quick way to start a brand new
search instead of manually clearing the query and re-running `<C-o>`/`<C-e>`
with empty input for each filter; and wanted the last query + filters to
persist when reopening a picker rather than starting from a blank prompt
each time.

### conform.nvim — markdown/mdx prettier warn-once (2026-06-28)

`format_on_save` is a function; for markdown/mdx it calls
`lua/methods/markdown-prettier-warn.lua` before returning format options.

**Why:** prettier must come from each project's `node_modules` (not global
PATH). If it's absent, conform silently skips formatting with no feedback.
The warn module fires `vim.notify(WARN)` once per session when
`get_formatter_info("prettier", bufnr).available` is false, then stays
silent. Dependency-injected (check_fn, notify_fn) so unit-tested in
`tests/e2e_spec.lua` ("markdown prettier warn:" tests).

### nvim-treesitter — removed (2026-06-26), then reinstated on `main` (2026-07-06)

**2026-06-26:** plugin removed; `lua/config/treesitter.lua` added a single `FileType` autocmd calling `vim.treesitter.start()`, with the belief that nvim 0.12.3 bundles enough parsers+queries on its own.

**Why removed:** nvim-treesitter's `master` branch was archived. Its bundled highlight queries referenced node types (e.g. `underscore` in gdscript) that don't exist in the parser binaries, causing `E5108` errors on every file open.

**Correction (2026-07-06):** the "nvim 0.12.3 bundles 37 parsers with matching queries" claim above was wrong — verified nvim 0.12.3 only ships bundled highlight queries for **7** languages (`c`, `lua`, `markdown`, `markdown_inline`, `query`, `vim`, `vimdoc`). Every other filetype relied on leftover parser binaries orphaned in `~/.local/share/nvim/site/parser` from the old plugin install. `vim.treesitter.start()` succeeds whenever a parser binary exists — even an orphan with no matching query — and that success **disables legacy regex `:syntax` highlighting** for the buffer. Net effect: PHP, Go, Rust, Python, YAML, JSON, HTML, TOML, and more rendered with **zero** highlighting (confirmed via `vim.treesitter.get_captures_at_pos` returning empty). CSS/JS/TS were the only ones still working, because `catppuccin` happens to ship its own query files for those three.

**Fix:** reinstated `nvim-treesitter`, pinned to the `main` branch (see `lua/plugins/treesitter.lua`) — a full rewrite, actively maintained (unlike the frozen `master`), that does nothing but install parsers + their matching query files as one versioned pair per commit; it does not touch highlighting at all, so the existing `lua/config/treesitter.lua` FileType autocmd needed no changes. Because parser and query come from the same commit, the original `master`-branch mismatch (query referencing a node type the parser doesn't produce) can't recur the same way.

**Gotcha hit during setup:** `require('nvim-treesitter').install()` treats a language as "already installed" (and silently skips it) if **either** its query directory **or** its parser file exists (`config.get_installed()` unions both listings). An interrupted first install left query dirs in place without compiled parsers for ~25 languages; every later `install()` call skipped them without error. Fixed by re-running with `{ force = true }` once. If highlighting for a specific language ever silently stops working again after an interrupted `:TSUpdate`, this is the first thing to check — look for a query dir under `~/.local/share/nvim/site/queries/<lang>` with no matching `<lang>.so` in `~/.local/share/nvim/site/parser`, and force-reinstall.

**Trade-off:** none remaining — `:TSInstall`/`:TSUpdate` are back. Indent is still nvim built-in (no treesitter-indent module was enabled).

### nvim-lspconfig — intelephense added for PHP (2026-07-06)

Added `"intelephense"` to `ensure_installed` and `vim.lsp.enable({...})` in `lua/plugins/lsp.lua`.

**Why:** intelephense was already installed via Mason but never referenced by `mason-lspconfig`'s `ensure_installed` or `vim.lsp.enable`, so it never attached to PHP buffers — a plain oversight, not a bug in any plugin. `nvim-lspconfig` already ships `lsp/intelephense.lua`, so no server-specific config was needed beyond enabling it.

### snacks.nvim — scope treesitter injections disabled

`scope.treesitter.injections` set to `false` in `lua/plugins/snacks.lua`.

**Why:** nvim 0.12.3 has a bug in async treesitter parsing with injection queries. When opening a markdown file, snacks scope triggered an async parse with injections enabled (the default). During injection query evaluation, `vim.treesitter.get_range(node)` was called with a nil `TSNode`, crashing with `E5108: attempt to call method 'range' (a nil value)`. Disabling injections stops snacks from passing `range=true` to the async parser, avoiding the nil node path. Injections are only meaningful for multi-language files (Vue, JSX templates); Go/Lua/Rust/TS are unaffected.
