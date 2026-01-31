return {
  "nvim-treesitter/nvim-treesitter",
  commit = "f8bbc31",
  build = ":TSUpdate",
  init = function ()
    require("nvim-treesitter").setup({
      ensure_installed = { "lua", "jsdoc", "json", "css", "scss", "markdown", "rust", "go" },
      highlight = { enable = true }
    })
  end
}
