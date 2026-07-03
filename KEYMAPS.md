# KEYMAPS

- **when**:
    - `n` - normal mode;
    - `i` - insert mode;
    - `v` - visual mode;
    - `x` - visual line mode.

| Keys | When | Plugin | Description |
|---|---|---|---|---|
| **\<C-h>** | n | `lua/keymaps.lua` | Navigate to the left window |
| **\<C-j>** | n | `lua/keymaps.lua` | Navigate to the down window |
| **\<C-k>** | n | `lua/keymaps.lua` | Navigate to the up window |
| **\<C-l>** | n | `lua/keymaps.lua` | Navigate to the right window |
| **gd** | n | `lua/plugins/lsp.lua` | LSP: goto definition (buffer-local on attach) |
| **grr** | n | `lua/plugins/lsp.lua` | LSP: references |
| **K** | n | `lua/plugins/lsp.lua` | LSP: hover |
| **\<leader>rn** | n | `lua/plugins/lsp.lua` | LSP: rename |
| **\<leader>ca** | n | `lua/plugins/lsp.lua` | LSP: code action |
| **\<leader>?** | n | `lua/plugins/which-key.lua` | Show buffer-local keymaps (which-key) |
| **\<leader>xx** | n | `lua/plugins/trouble.lua` | Trouble: diagnostics |
| **\<leader>xX** | n | `lua/plugins/trouble.lua` | Trouble: buffer diagnostics |
| **\<leader>xs** | n | `lua/plugins/trouble.lua` | Trouble: symbols |
| **\<leader>xl** | n | `lua/plugins/trouble.lua` | Trouble: LSP defs/refs |
| **\<leader>xL** | n | `lua/plugins/trouble.lua` | Trouble: location list |
| **\<leader>xQ** | n | `lua/plugins/trouble.lua` | Trouble: quickfix list |
| **\<leader>ff** | n | `lua/plugins/telescope.lua` | Telescope: find files |
| **\<leader>fg** | n | `lua/plugins/telescope.lua` | Telescope: live grep |
| **\<leader>fb** | n | `lua/plugins/telescope.lua` | Telescope: buffers |
| **\<leader>fh** | n | `lua/plugins/telescope.lua` | Telescope: help tags |
| **\<leader>fr** | n | `lua/plugins/telescope.lua` | Telescope: recent files |
| **\<C-j>** | i | `lua/plugins/telescope.lua` | Telescope prompt: cycle to next search history entry |
| **\<C-k>** | i | `lua/plugins/telescope.lua` | Telescope prompt: cycle to previous search history entry |
| **\<leader>cf** | n | `lua/plugins/conform.lua` | Format buffer (conform) |
| **]c** | n | `lua/plugins/gitsigns.lua` | Git: next hunk (buffer-local) |
| **[c** | n | `lua/plugins/gitsigns.lua` | Git: prev hunk (buffer-local) |
| **\<leader>gp** | n | `lua/plugins/gitsigns.lua` | Git: preview hunk |
| **\<leader>gb** | n | `lua/plugins/gitsigns.lua` | Git: blame line |
| **\<leader>gr** | n | `lua/plugins/gitsigns.lua` | Git: reset hunk |
| **\<leader>m** | n | `ftplugin/markdown.lua` | Open mermaid block under cursor in Mermaid Live Editor (markdown-local) |
| **s** | n,x,o | `lua/plugins/flash.lua` | Flash jump |
| **S** | n,x,o | `lua/plugins/flash.lua` | Flash treesitter |
| **r** | o | `lua/plugins/flash.lua` | Remote flash (operator) |
| **\<A-A>** | i | `lua/plugins/minuet.lua` | Minuet: accept whole autocomplete suggestion |
| **\<A-a>** | i | `lua/plugins/minuet.lua` | Minuet: accept one line of suggestion |
| **\<A-z>** | i | `lua/plugins/minuet.lua` | Minuet: accept N lines (prompts for count) |
| **\<A-]>** | i | `lua/plugins/minuet.lua` | Minuet: next suggestion |
| **\<A-[>** | i | `lua/plugins/minuet.lua` | Minuet: previous suggestion |
| **\<A-e>** | i | `lua/plugins/minuet.lua` | Minuet: dismiss suggestion |
| **\<A-C>** | i | `lua/plugins/minuet.lua` | Minuet: complete with extra context (one-shot, larger window) |
| **\\[** | n | `lua/plugins/bufferline.lua` | Previous buffer |
| **\\]** | n | `lua/plugins/bufferline.lua` | Next buffer |
| **\<leader>q** | n | `lua/config/keymaps.lua` | Close buffer |
| **\<leader>sr** | n | `lua/plugins/grug-far.lua` | grug-far: search & replace across files |
| **\<leader>sr** | v | `lua/plugins/grug-far.lua` | grug-far: search & replace within visual selection |