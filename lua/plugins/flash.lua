-- Jump motions. Lazy: keys only.
return {
  "folke/flash.nvim",
  commit = "fcea7ff883235d9024dc41e638f164a450c14ca2",
  event = "VeryLazy",
  opts = {},
  keys = {
    { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
    { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
  },
}
