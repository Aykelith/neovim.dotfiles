return function (lazy_config)
  table.insert(lazy_config, {
    "nvim-tree/nvim-web-devicons",
    lazy = true
  })

  table.insert(lazy_config, {
    "famiu/bufdelete.nvim",
  })

  return lazy_config
end
