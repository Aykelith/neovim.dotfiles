return {
  "folke/snacks.nvim",
  commit = "882c996cf28183f4d63640de0b4c02ec886d01f2",
  priority = 1000,
  lazy = false,
  opts = {
    bigfile = { enabled = true },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
    scroll = { enabled = false },
    dashboard = { enabled = false },
    indent = { animate = { enabled = false } },
    scope = { treesitter = { injections = false } },
    picker = {
      icons = {
        git = {
          untracked = "U",
          ignored = "I",
          modified = "M",
        },
      },
      sources = {
        explorer = {
          hidden = true,
          ignored = true,
          jump = {
            close = true,
          },
          actions = {
            -- Open the item under cursor in the OS default app (image viewer, etc.)
            open_in_app = function(_, item)
              if item and item.file then vim.ui.open(item.file) end
            end,
          },
          layout = {
            preset = "default",
          },
          format = function(item, picker)
            local result = Snacks.picker.format.file(item, picker)
            if item.dir and item.status then
              for _, chunk in ipairs(result) do
                if chunk.virt_text_pos == "right_align" and chunk.virt_text and chunk.virt_text[1] then
                  chunk.virt_text[1][1] = "●"
                  break
                end
              end
            end
            return result
          end,
          win = {
            input = {
              keys = {
                ["<CR>"] = { "tab", mode = { "n", "i" } },
              },
            },
            list = {
              keys = {
                ["<CR>"] = { "tab", mode = { "n", "i" } },
                ["O"] = "open_in_app",
              },
            },
          },
        },
      },
    },
  },
}
