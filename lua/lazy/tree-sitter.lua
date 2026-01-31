return {
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  commit = "19c729d",
  build = ":TSUpdate",
  init = function ()
    require("nvim-treesitter").install { "lua", "jsdoc", "json", "css", "scss", "markdown", "rust", "go" }
  end
}
