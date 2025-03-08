return function (lazy_config)
  table.insert(lazy_config, {
    "nvim-tree/nvim-web-devicons",
    commit = "ab4cfee",
    lazy = true
  })

  return lazy_config
end
