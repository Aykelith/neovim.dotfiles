return {
  "akinsho/bufferline.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      diagnostics = "nvim_lsp",
      show_buffer_close_icons = true,
      show_close_icon = false,
      separator_style = "thin",
      offsets = {
        {
          filetype = "snacks_layout_box",
          text = "Explorer",
          text_align = "center",
          separator = true,
        },
      },
    },
  },
  keys = {
    { "<Bslash>[", "<cmd>BufferLineCyclePrev<CR>", desc = "Previous buffer" },
    { "<Bslash>]", "<cmd>BufferLineCycleNext<CR>", desc = "Next buffer" },
  },
}
