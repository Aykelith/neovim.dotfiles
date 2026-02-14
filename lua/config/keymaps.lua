-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local opts = { noremap = true, silent = true }

-- Shorten function name
local keymap = vim.keymap.set

keymap("n", "<localleader>d", function()
  Snacks.bufdelete()
end, { desc = "Delete Buffer", noremap = true, silent = true })
keymap("n", "<localleader>[", "<cmd>bprevious<cr>", { desc = "Prev Buffer", noremap = true, silent = true })
keymap("n", "<localleader>]", "<cmd>bnext<cr>", { desc = "Next Buffer", noremap = true, silent = true })

-- Normal --
-- Better window navigation, WinMove defined in `winmove.lua`
keymap("n", "<C-h>", ":call WinMove('h')<CR>", opts)
keymap("n", "<C-j>", ":call WinMove('j')<CR>", opts)
keymap("n", "<C-k>", ":call WinMove('k')<CR>", opts)
keymap("n", "<C-l>", ":call WinMove('l')<CR>", opts)

keymap("n", "<leader>e", function()
  Snacks.explorer()
end, { noremap = true, silent = true, desc = "File Explorer (cwd)" })
