local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("options")
require("win-move")
require("keymaps")

local lazy_config = {
  require("lazy/colorscheme"),
  require("lazy/tabline"),
  require("lazy/file-explorer"),
  require("lazy/fuzzy-finder"),
  require("lazy/tree-sitter"),
  require("lazy/status-line"),
  require("lazy/diagnostics"),
}

lazy_config = require("lazy/others")(lazy_config)
lazy_config = require("lazy/lsp")(lazy_config)

require("lazy").setup(lazy_config)
