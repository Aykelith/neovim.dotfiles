return function (lazy_config)
  table.insert(lazy_config, {
    "williamboman/mason.nvim"
  })

  table.insert(lazy_config, {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
      "williamboman/mason.nvim",
    },
  })

  table.insert(lazy_config, {
    "VonHeikemen/lsp-zero.nvim",
    branch = 'v3.x',
    dependencies = {
      "williamboman/mason-lspconfig.nvim"
    },
    init = function ()
      local lsp_zero = require('lsp-zero')
      lsp_zero.extend_lspconfig()

      lsp_zero.on_attach(function(client, bufnr)
        -- see :help lsp-zero-keybindings
        -- to learn the available actions
        lsp_zero.default_keymaps({buffer = bufnr})
      end)

      require('mason').setup({})
      require('mason-lspconfig').setup({
        ensure_installed = {},
        handlers = {
          -- this first function is the "default handler"
          -- it applies to every language server without a "custom handler"
          function(server_name)
            require('lspconfig')[server_name].setup({})
          end,
        },
      })
    end
  })

  table.insert(lazy_config, {
    "neovim/nvim-lspconfig"
  })

  table.insert(lazy_config, {
    "hrsh7th/cmp-nvim-lsp"
  })

  table.insert(lazy_config, {
    "hrsh7th/nvim-cmp"
  })

  table.insert(lazy_config, {
    "L3MON4D3/LuaSnip"
  })

  return lazy_config
end
