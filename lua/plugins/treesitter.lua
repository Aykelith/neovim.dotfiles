-- nvim-treesitter (main branch): a full rewrite that only installs parsers +
-- their matching query files. Highlighting itself is native nvim, started by
-- the FileType autocmd in lua/config/treesitter.lua. Unlike the archived
-- master branch, parser and query versions are locked together per commit,
-- so :TSUpdate can't drift them apart.
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  commit = "4916d6592ede8c07973490d9322f187e07dfefac",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").install(require("config.treesitter-parsers"))
  end,
}
