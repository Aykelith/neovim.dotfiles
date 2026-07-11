-- Debugging via DAP. Godot 4 is the debug adapter (built-in DAP server on
-- 127.0.0.1:6006); nvim-dap connects to it. Lazy: loads on a gdscript buffer.
-- Godot side: Debug > "Debug with External Editor" on, and
-- Editor Settings > Network > Debug Adapter port = 6006. Godot must be running.
return {
  "mfussenegger/nvim-dap",
  commit = "9e848e09a697ee95302a3ef2dd43fd6eb709e570",
  ft = "gdscript",
  config = function()
    local dap = require("dap")

    dap.adapters.godot = {
      type = "server",
      host = "127.0.0.1",
      port = 6006,
    }
    dap.configurations.gdscript = {
      {
        type = "godot",
        request = "launch",
        name = "Launch scene",
        project = "${workspaceFolder}",
      },
    }

    -- Red circle in the gutter for breakpoints; arrow for the stopped line.
    vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "#e51400" })
    vim.api.nvim_set_hl(0, "DapStopped", { fg = "#98c379" })
    vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DapBreakpoint" })
    vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DapStopped", linehl = "Visual" })

    local map = function(lhs, fn, desc)
      vim.keymap.set("n", lhs, fn, { desc = desc })
    end
    map("<leader>db", dap.toggle_breakpoint, "DAP: toggle breakpoint")
    map("<leader>dc", dap.continue, "DAP: continue / start")
    map("<leader>do", dap.step_over, "DAP: step over")
    map("<leader>di", dap.step_into, "DAP: step into")
    map("<leader>dO", dap.step_out, "DAP: step out")
    map("<leader>dt", dap.terminate, "DAP: terminate")
  end,
}
