return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  init = function ()
    require("nvim-treesitter.configs").setup({
      ensure_installed = { "lua", "jsdoc", "json", "css", "scss", "markdown" },
      highlight = { enable = true }
    })
  end
}
