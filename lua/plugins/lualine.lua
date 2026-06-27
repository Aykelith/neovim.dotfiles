-- Statusline. Lazy: VeryLazy (after startup, before idle).

-- minuet "thinking" indicator. Self-contained (listens to minuet's User events)
-- so it does NOT require minuet's own lualine component — that would eager-load
-- minuet and break its InsertEnter-lazy gating. minuet fires MinuetRequestStarted
-- when it asks Ollama and MinuetRequestFinished when the answer lands.
local minuet_busy = false
vim.api.nvim_create_autocmd("User", {
  pattern = { "MinuetRequestStarted", "MinuetRequestFinished" },
  callback = function(ev)
    minuet_busy = ev.match == "MinuetRequestStarted"
    -- ponytail: static badge, no spinner. Redraw on transition so it appears
    -- promptly instead of waiting for lualine's refresh tick. Want animation?
    -- drive a uv timer here while busy.
    vim.cmd("redrawstatus")
  end,
})
local function minuet_status()
  return minuet_busy and "◍ minuet…" or ""
end

return {
  "nvim-lualine/lualine.nvim",
  commit = "221ce6b2d999187044529f49da6554a92f740a96",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      theme = "catppuccin-nvim",
      globalstatus = true,
      section_separators = "",
      component_separators = "",
    },
    sections = {
      -- lualine_x default is { encoding, fileformat, filetype }; prepend minuet.
      lualine_x = { minuet_status, "encoding", "fileformat", "filetype" },
    },
  },
}
