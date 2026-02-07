-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local options = {
  backup = false, -- disable creating a backup file
  smartcase = false, -- smart case
  swapfile = false, -- creates a swapfile
  timeoutlen = 1000, -- mapping delay
  ttimeoutlen = 100, -- key code delay
  writebackup = false, -- if a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited
  expandtab = true, -- convert tabs to spaces
  shiftwidth = 4, -- the number of spaces inserted for each indentation
  tabstop = 4, -- insert 4 spaces for a tab
  number = true, -- set numbered lines
  relativenumber = true, -- set relative numbered lines
  numberwidth = 4, -- set number column width to 2 {default 4}
  scrolloff = 8, -- is one of my fav
  sidescrolloff = 8,
  showtabline = 2,
}

for k, v in pairs(options) do
  vim.opt[k] = v
end
