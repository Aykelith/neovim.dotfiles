-- Multi-file search & replace. Lazy: command + keys only.
return {
  "MagicDuck/grug-far.nvim",
  commit = "c69859c1d5427ab5fc7ed12380ab521b4e336691",
  cmd = { "GrugFar", "GrugFarWithin" },
  opts = {},
  keys = {
    { "<leader>sr", "<cmd>GrugFar<cr>", desc = "Search & Replace (grug-far)" },
    { "<leader>sr", "<cmd>GrugFarWithin<cr>", mode = "v", desc = "Search & Replace in Selection (grug-far)" },
  },
}
