return function (lazy_config)
  table.insert(lazy_config, {
    "williamboman/mason.nvim",
    commit = "44d1e90",
    opt = {},
  })

  table.insert(lazy_config, {
    "neovim/nvim-lspconfig",
    tag = "v2.5.0"
  })

  table.insert(lazy_config, {
    "williamboman/mason-lspconfig.nvim",
    commit = "f2fa604",
    lazy = false,
    opt = {
      ensure_installed = {"rust_analyzer"},
    },
    dependencies = {
      "williamboman/mason.nvim",
      "neovim/nvim-lspconfig",
    },
  })

  table.insert(lazy_config, {
    "hrsh7th/cmp-nvim-lsp"
  })

  table.insert(lazy_config, {
    "hrsh7th/nvim-cmp"
  })

  -- table.insert(lazy_config, {
  --  "L3MON4D3/LuaSnip"
  --})

  return lazy_config
end
