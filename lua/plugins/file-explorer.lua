return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            hidden = true,
            ignored = true,
            jump = {
              close = true,
            },
            layout = {
              preset = "default",
            },
          },
        },
      },
    },
  },
}
