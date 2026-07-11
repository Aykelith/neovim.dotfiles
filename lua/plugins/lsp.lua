-- LSP: native vim.lsp.enable + nvim-lspconfig configs + Mason server management.
return {
  "neovim/nvim-lspconfig",
  commit = "3371bf298c1f56efc26771ee961f461176958fb5",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    { "mason-org/mason.nvim", commit = "2a6940af80375532e5e9e7c1f2fc6319a1b7a69d", config = true },
    { "mason-org/mason-lspconfig.nvim", commit = "50bf3871b539896bd0650b882f6e6b467cc1c1eb" },
  },
  config = function()
    -- Mason downloads these; rust_analyzer is taken from PATH (rustup/cargo).
    require("mason-lspconfig").setup({
      ensure_installed = { "lua_ls", "gopls", "ts_ls", "intelephense" },
      automatic_enable = false,
    })

    -- Advertise blink.cmp's completion capabilities to every server. Requiring
    -- blink here triggers lazy to load it (first buffer), so capabilities are
    -- ready before any server attaches.
    local ok, blink = pcall(require, "blink.cmp")
    local capabilities = ok and blink.get_lsp_capabilities()
      or vim.lsp.protocol.make_client_capabilities()
    vim.lsp.config("*", { capabilities = capabilities })

    -- Server-specific tweaks layered onto nvim-lspconfig's defaults.
    vim.lsp.config("lua_ls", {
      settings = { Lua = { diagnostics = { globals = { "vim" } } } },
    })

    -- In the monorepo, root_markers checks '.git' before 'composer.json' by
    -- default, so it resolves to the repo root instead of the nested PHP
    -- project (e.g. admin/), pulling every project into intelephense's
    -- workspace. Check composer.json first so nested projects stay scoped.
    vim.lsp.config("intelephense", {
      root_markers = { "composer.json", ".git" },
    })

    -- GDScript's LSP lives inside the running Godot editor (TCP 127.0.0.1:6005),
    -- not a Mason binary. Connect natively so diagnostics/completion attach when
    -- Godot is open on the project. GDScript_Port env overrides if Godot's
    -- Editor Settings > Network > Language Server port differs.
    vim.lsp.config("gdscript", {
      cmd = vim.lsp.rpc.connect("127.0.0.1", tonumber(vim.env.GDScript_Port) or 6005),
      root_markers = { "project.godot", ".git" },
    })

    vim.lsp.enable({ "lua_ls", "gopls", "ts_ls", "rust_analyzer", "intelephense", "gdscript" })

    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        local map = function(keys, fn, desc)
          vim.keymap.set("n", keys, fn, { buffer = args.buf, desc = "LSP: " .. desc })
        end
        map("gd", vim.lsp.buf.definition, "Goto Definition")
        map("grr", vim.lsp.buf.references, "References")
        map("K", vim.lsp.buf.hover, "Hover")
        map("<leader>rn", vim.lsp.buf.rename, "Rename")
        map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
      end,
    })
  end,
}
