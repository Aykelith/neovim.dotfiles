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

vim.filetype.add({
  extension = {
    mdx = 'markdown',
  },
})

local lazy_config = {
  require("lazy/lsp"),
  require("lazy/colorscheme"),
  require("lazy/tabline"),
  require("lazy/file-explorer"),
  require("lazy/fuzzy-finder"),
  require("lazy/tree-sitter"),
  require("lazy/status-line"),
  require("lazy/diagnostics"),
  require("lazy/git"),
  require("lazy/others"),
}

require("lazy").setup(lazy_config)

vim.api.nvim_create_autocmd('FileType', {
  pattern = { '<filetype>' },
  callback = function()
    vim.treesitter.start()
    vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    vim.wo[0][0].foldmethod = 'expr'
  end,
})
