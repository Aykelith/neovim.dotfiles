return {
  "folke/snacks.nvim",
  commit = "882c996cf28183f4d63640de0b4c02ec886d01f2",
  priority = 1000,
  lazy = false,
  opts = {
    bigfile = { enabled = true },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
    scroll = { enabled = false },
    dashboard = { enabled = false },
    indent = { animate = { enabled = false } },
    scope = { treesitter = { injections = false } },
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
          win = {
            input = {
              keys = {
                ["<CR>"] = { "tab", mode = { "n", "i" } },
              },
            },
            list = {
              keys = {
                ["<CR>"] = { "tab", mode = { "n", "i" } },
              },
            },
          },
        },
      },
    },
  },
}
