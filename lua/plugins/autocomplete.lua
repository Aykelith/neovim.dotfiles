return {
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        preset = "default", -- or 'super-tab' / 'enter'

        -- Disable Enter
        ["<CR>"] = { "fallback" },

        -- Set Ctrl-y to confirm
        ["<C-y>"] = { "select_and_accept" },
      },
    },
  },
}
