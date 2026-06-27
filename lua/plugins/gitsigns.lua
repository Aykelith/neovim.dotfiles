-- Git gutter signs + hunk nav. Lazy: loads when a file opens.
return {
  "lewis6991/gitsigns.nvim",
  commit = "2038c666bd9d8a0b7349a0b6ee00dc83104b9ecf",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    on_attach = function(buf)
      local gs = require("gitsigns")
      local map = function(keys, fn, desc)
        vim.keymap.set("n", keys, fn, { buffer = buf, desc = "Git: " .. desc })
      end
      map("]c", function() gs.nav_hunk("next") end, "Next Hunk")
      map("[c", function() gs.nav_hunk("prev") end, "Prev Hunk")
      map("<leader>gp", gs.preview_hunk, "Preview Hunk")
      map("<leader>gb", gs.blame_line, "Blame Line")
      map("<leader>gr", gs.reset_hunk, "Reset Hunk")
    end,
  },
}
