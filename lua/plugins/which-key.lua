return {
  "folke/which-key.nvim",
  commit = "3aab2147e74890957785941f0c1ad87d0a44c15a",
  event = "VeryLazy",
  opts = {},
  keys = {
    {
      "<leader>?",
      function() require("which-key").show({ global = false }) end,
      desc = "Buffer Local Keymaps (which-key)",
    },
  },
}
