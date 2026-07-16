local opts = { noremap = true, silent = true }

-- Shorten function name
local keymap = vim.keymap.set

-- Normal --
-- Better window navigation, WinMove defined in `winmove.lua`
keymap("n", "<C-h>", ":call WinMove('h')<CR>", opts)
keymap("n", "<C-j>", ":call WinMove('j')<CR>", opts)
keymap("n", "<C-k>", ":call WinMove('k')<CR>", opts)
keymap("n", "<C-l>", ":call WinMove('l')<CR>", opts)

keymap("n", "<leader>e", function()
	Snacks.explorer()
end, { noremap = true, silent = true, desc = "File Explorer (cwd)" })

-- Buffer close (keeps split windows open, see methods/close-buffer.lua)
keymap("n", "<leader>q", function()
	require("methods.close-buffer").close()
end, { noremap = true, silent = true, desc = "Close buffer" })
