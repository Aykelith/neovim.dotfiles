local config = {
  "sainnhe/sonokai",
  name = "sonokai",
  lazy = false,
  priority = 1000,
  config = function()
    -- load the colorscheme here
    -- vim.g.sonokai_style = "sushia"
    vim.g.sonokai_enable_italic = true
    vim.cmd([[colorscheme sonokai]])
  end,
}

return config
