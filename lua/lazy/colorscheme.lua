local config = {
  "catppuccin/nvim",
  name = "catppuccin",
  commit = "5b5e3ae",
  lazy = false,
  priority = 1000,
  config = function()
    -- load the colorscheme here
    vim.cmd([[colorscheme catppuccin-macchiato]])
  end,
}

return config
