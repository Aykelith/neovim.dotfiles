# Alex's NVIM config

## Keys

References:

- **when**:
    - `n` - normal mode;
    - `i` - insert mode;
    - `v` - visual mode;
    - `x` - visual line mode.

| Keys | When | Plugin | File defined | Description |
|---|---|---|---|---|
| **\<C-h>** | n | `lua/keymaps.lua` | | Navigate to the left window |
| **\<C-j>** | n | `lua/keymaps.lua` | | Navigate to the down window |
| **\<C-k>** | n | `lua/keymaps.lua` | | Navigate to the up window |
| **\<C-l>** | n | `lua/keymaps.lua` | | Navigate to the right window |
| **jk** | i | `lua/keymaps.lua` | | Exit fast Insert Mode |
| **\<Leader>ff** | n | `lua/lazy/fuzzy-finder.lua` | Telescope | Open Telescope's file finder |
| **\<Leader>fg** | n | `lua/lazy/fuzzy-finder.lua` | Telescope | Open Telescope's grep finder |
| **\<Leader>fb** | n | `lua/lazy/fuzzy-finder.lua` | Telescope | Open Telescope's buffer finder |
| **\<Leader>fh** | n | `lua/lazy/fuzzy-finder.lua` | Telescope | Open Telescope's help finder  |
| **\<Leader>fu** | n | `lua/lazy/fuzzy-finder.lua` | Telescope | Open Telescope's undo stack |
| **\<C-Up>** | Telescope | `lua/lazy/fuzzy-finder.lua` | Telescope | Move up in the history of searched phrases |
| **\<C-Down>** | Telescope | `lua/lazy/fuzzy-finder.lua` | Telescope | Move down in the history of searched phrases |
| **\<C-k>** | Telescope:Grep finder | `lua/lazy/fuzzy-finder.lua` | Telescope | Quote the word under cursor |
| **\<Space>e** | n | `lua/lazy/file-explorer.lua` | neo-tree.nvim | Toggle file explorer |
| **\<Leader>xx** | n | `lua/lazy/diagnostics.lua` | trouble.nvim | Toggle diagnostics for current buffer |
| **\<Leader>xX** | n | `lua/lazy/diagnostics.lua` | trouble.nvim | Toggle diagnostics for all buffers |
| **\<C-y>** | i | ? | LSP | Apply the selected autocomplete option |
| **gl** | n | `lua/lazy/lsp.lua:lsp_zero.default_keymaps` | lsp-zero | Show the diagnostics on the current line in a floating window |
| **gd** | n | `lua/lazy/lsp.lua:lsp_zero.default_keymaps` | lsp-zero | Go to the definition of the symbol your cursor is on it |
| **d** | Filesystem | `lua/lazy/file-explorer.lua` | neo-tree.nvim | Delete a file/dir (confirmation needed) |
| **i** | Filesystem | `lua/lazy/file-explorer.lua` | neo-tree.nvim | Show details on that file/dir |
| **l** | Filesystem | `lua/lazy/file-explorer.lua` | neo-tree.nvim | Show directory children |
| **h** | Filesystem | `lua/lazy/file-explorer.lua` | neo-tree.nvim | Collapse directory children |
| **H** | Filesystem | `lua/lazy/file-explorer.lua` | neo-tree.nvim | Collapse all directories |

## Plugins

### Telescope

Repository: [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

File: `lua/lazy/fuzzy-finder.lua`
