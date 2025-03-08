local config = {
  "romgrk/barbar.nvim",
  commit = "807bede",
  dependencies = {
    "nvim-tree/nvim-web-devicons"
  },
  keys = {
    { "<Leader>d", "<Cmd>BufferClose<CR>", desc = "[tabline] Delete current buffer", silent = true },
    { "<Leader>[", "<Cmd>BufferPrevious<CR>", desc = "[tabline] Switch to previous buffer", silent = true, noremap = true },
    { "<Leader>]", "<Cmd>BufferNext<CR>", desc = "[tabline] Switch to next buffer", silent = true, noremap = true }
  },
  lazy = false,
  init = function()
    vim.g.barbar_auto_setup = false
  end,
  opts = {
    animation = false,
    auto_hide = false,
    clickable = false,
  }
}

return config
