return function (lazy_config)
  table.insert(lazy_config, {
    "nvim-tree/nvim-web-devicons",
    commit = "8033534",
    lazy = true
  })

  return lazy_config
end
