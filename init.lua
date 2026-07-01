-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.options")
require("config.treesitter")
require("methods.win-move")
require("config.keymaps")
require("config.commands")

vim.filetype.add({
  extension = {
    mdx = 'markdown',
  },
})

-- NerdFont glyphs in icon plugins. ponytail: the font itself is an OS install,
-- not a plugin; this only tells plugins they may use glyphs.
vim.g.have_nerd_font = true

require("lazy").setup({
  spec = { { import = "plugins" } },
  rocks = { enabled = true, hererocks = true }, -- luarocks support (lazy bootstraps hererocks)
  install = { colorscheme = { "habamax" } },
  checker = { enabled = false },
})
