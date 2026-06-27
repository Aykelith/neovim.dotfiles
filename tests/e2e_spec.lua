local h = require("helpers")

-- Each test spawns its own child nvim and tears it down.
local function with_child(fn)
  local c = h.start_child()
  local ok, err = pcall(fn, c)
  h.stop(c)
  if not ok then error(err, 0) end
end

local T = {}

-- Real keystrokes reach the buffer: type in insert mode, read it back.
T["simulates keystrokes into a buffer"] = function()
  with_child(function(c)
    h.input(c, "ihello world<Esc>")
    local line = h.lua(c, "return vim.api.nvim_get_current_line()")
    assert(line == "hello world", "got: " .. vim.inspect(line))
  end)
end

-- The real config loaded (options + leader).
T["loads user config (options & leader)"] = function()
  with_child(function(c)
    assert(h.lua(c, "return vim.g.mapleader") == " ", "mapleader")
    assert(h.lua(c, "return vim.o.shiftwidth") == 4, "shiftwidth")
  end)
end

-- Window-nav keymap from keymaps.lua exists.
T["registers <C-h> window-nav keymap"] = function()
  with_child(function(c)
    local found = h.lua(c, [[
      for _, m in ipairs(vim.api.nvim_get_keymap("n")) do
        if m.lhs == "<C-H>" then return true end
      end
      return false
    ]])
    assert(found, "<C-h> not mapped")
  end)
end

-- Lazy installed and loaded the requested plugins.
T["lazy has the requested plugins"] = function()
  with_child(function(c)
    local names = h.lua(c, [[
      local out = {}
      for _, p in ipairs(require("lazy").plugins()) do out[p.name] = true end
      return out
    ]])
    for _, want in ipairs({
      "which-key.nvim", "trouble.nvim", "snacks.nvim", "nvim-lspconfig", "mason.nvim",
      "catppuccin", "nvim-treesitter", "lualine.nvim", "blink.cmp",
      "telescope.nvim", "gitsigns.nvim", "conform.nvim", "flash.nvim",
      "minuet-ai.nvim",
    }) do
      assert(names[want], "missing plugin: " .. want)
    end
  end)
end

-- Colorscheme applied eagerly at startup.
T["catppuccin colorscheme is active"] = function()
  with_child(function(c)
    local name = h.lua(c, "return vim.g.colors_name")
    assert(name and name:match("^catppuccin"), "colors_name: " .. vim.inspect(name))
  end)
end

-- Only essential plugins load at startup; the rest stay lazy until triggered.
T["heavy plugins are not loaded at startup"] = function()
  with_child(function(c)
    -- snacks + colorscheme are essential and must be up.
    assert(h.lua(c, "return package.loaded['snacks'] ~= nil"), "snacks should load at startup")
    -- These are cmd/keys/event-gated and must NOT be loaded before use.
    for _, mod in ipairs({ "telescope", "gitsigns", "conform" }) do
      assert(
        h.lua(c, "return package.loaded[...] == nil", mod),
        mod .. " loaded at startup (should be lazy)"
      )
    end
  end)
end

-- Minuet is InsertEnter-gated: absent at startup, loads when insert begins.
T["minuet loads on InsertEnter (lazy)"] = function()
  with_child(function(c)
    assert(
      h.lua(c, "return package.loaded['minuet'] == nil"),
      "minuet loaded at startup (should be lazy until InsertEnter)"
    )
    h.input(c, "i")
    local loaded = h.wait(function()
      return h.lua(c, "return package.loaded['minuet'] ~= nil")
    end, 5000)
    h.input(c, "<Esc>")
    assert(loaded, "minuet did not load on InsertEnter")
  end)
end

-- Telescope command registered (lazy cmd stub) and loads on use.
T["Telescope command exists"] = function()
  with_child(function(c)
    local has = h.wait(function()
      return h.lua(c, "return vim.fn.exists(':Telescope') == 2")
    end, 5000)
    assert(has, ":Telescope not defined")
  end)
end

-- gitsigns + treesitter highlight engage when a real file opens.
T["gitsigns loads on file open"] = function()
  with_child(function(c)
    h.lua(c, "vim.cmd.edit(...)", "tests/helpers.lua")
    local loaded = h.wait(function()
      return h.lua(c, "return package.loaded['gitsigns'] ~= nil")
    end, 5000)
    assert(loaded, "gitsigns did not load on BufReadPre")
  end)
end

-- Trouble command is available after opening a file.
T["Trouble command exists"] = function()
  with_child(function(c)
    h.lua(c, "vim.cmd.edit(...)", "tests/helpers.lua")
    local has = h.wait(function()
      return h.lua(c, "return vim.fn.exists(':Trouble') == 2")
    end, 5000)
    assert(has, ":Trouble not defined")
  end)
end

-- snacks loaded at startup.
T["snacks is loaded"] = function()
  with_child(function(c)
    assert(h.lua(c, "return package.loaded['snacks'] ~= nil"), "snacks not loaded")
  end)
end

-- Full LSP chain E2E: open a Rust file, rust_analyzer attaches and answers hover.
T["rust_analyzer attaches and responds (LSP E2E)"] = function()
  with_child(function(c)
    local dir = h.make_rust_project()
    h.lua(c, "vim.cmd.edit(...)", dir .. "/src/main.rs")

    local attached = h.wait(function()
      return h.lua(c, "return #vim.lsp.get_clients({ name = 'rust_analyzer' }) > 0")
    end, 30000, 200)
    assert(attached, "rust_analyzer did not attach")

    -- Cursor on `main`, ask for hover until the server has indexed.
    h.lua(c, "vim.api.nvim_win_set_cursor(0, { 1, 3 })")
    local hover = h.wait(function()
      return h.lua(c, [[
        local buf = vim.api.nvim_get_current_buf()
        local client = vim.lsp.get_clients({ name = "rust_analyzer" })[1]
        if not client then return nil end
        local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
        local res = vim.lsp.buf_request_sync(buf, "textDocument/hover", params, 3000)
        if not res then return nil end
        for _, r in pairs(res) do
          if r.result and r.result.contents then return true end
        end
        return nil
      ]])
    end, 30000, 500)
    assert(hover, "rust_analyzer returned no hover")
  end)
end

-- Real autocomplete E2E: minuet -> Ollama FIM -> inline ghost text appears.
-- Gated behind $MINUET_E2E so the normal suite doesn't need the docker server
-- running. The `run-autocomplete.sh` wrapper sets it after the container is up.
T["minuet produces inline ghost text (autocomplete E2E)"] = function()
  if vim.env.MINUET_E2E ~= "1" then return end -- skipped unless server is up
  with_child(function(c)
    -- Reproduce REAL usage ordering: set filetype BEFORE minuet loads (it's
    -- InsertEnter-lazy), so minuet's own FileType autocmd misses this buffer.
    -- Without the manual-arm fix in minuet.lua, auto-trigger stays off and no
    -- ghost text ever appears. Do NOT pre-load or pre-arm minuet here.
    h.lua(c, [[
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "def add(a, b):",
        "    return a + b",
        "",
        "",
        "def multiply(a, b):",
        "    return ",
      })
      vim.bo.filetype = "python" -- fires FileType while minuet is still unloaded
      vim.api.nvim_win_set_cursor(0, { 6, 11 }) -- end of "    return "
    ]])
    -- `A ` enters insert and types a space, firing InsertEnter (loads minuet)
    -- then CursorMovedI (auto-fetch — only if auto-trigger got armed).
    h.input(c, "A ")
    local visible = h.wait(function()
      return h.lua(c, "return package.loaded['minuet'] and require('minuet.virtualtext').action.is_visible()")
    end, 30000, 250)
    h.input(c, "<Esc>")
    assert(visible, "minuet showed no ghost text (auto-trigger not armed, or server down?)")
  end)
end

-- The one-shot "extra context" keymap is registered once minuet loads.
T["minuet registers the <A-C> extra-context keymap"] = function()
  with_child(function(c)
    h.input(c, "i<Esc>")
    local mapped = h.wait(function()
      return h.lua(c, [[
        for _, m in ipairs(vim.api.nvim_get_keymap("i")) do
          if m.lhs == "<M-C>" then return true end
        end
        return false
      ]])
    end, 5000)
    assert(mapped, "<A-C> not mapped in insert mode")
  end)
end

-- The server health-check command is registered when minuet loads.
T["minuet registers :MinuetHealth command"] = function()
  with_child(function(c)
    h.input(c, "i<Esc>") -- load minuet
    local has = h.wait(function()
      return h.lua(c, "return vim.fn.exists(':MinuetHealth') == 2")
    end, 5000)
    assert(has, ":MinuetHealth not defined")
  end)
end

-- The lualine minuet indicator is driven by a listener on minuet's request
-- User events; assert that listener exists (it's what flips the status badge).
T["lualine minuet indicator listens to request events"] = function()
  with_child(function(c)
    local found = h.lua(c, [[
      return #vim.api.nvim_get_autocmds({
        event = "User", pattern = "MinuetRequestStarted",
      }) > 0
    ]])
    assert(found, "no listener for MinuetRequestStarted (status indicator missing)")
  end)
end

-- Snacks explorer <CR> must open files in a new tab (not the current buffer).
T["snacks explorer <CR> opens file in new tab"] = function()
  with_child(function(c)
    assert(h.lua(c, "return package.loaded['snacks'] ~= nil"), "snacks not loaded")

    -- Write a temp file so the explorer has something to confirm on.
    local tmpfile = h.lua(c, [[
      local path = vim.fn.tempname() .. ".lua"
      local fh = assert(io.open(path, "w"))
      fh:write("return {}\n")
      fh:close()
      return path
    ]])
    local tmpdir = h.lua(c, "return vim.fn.fnamemodify(..., ':h')", tmpfile)

    -- Open explorer at the temp dir.
    h.lua(c, "require('snacks').picker.explorer({ cwd = ... })", tmpdir)

    -- Wait until a snacks picker window exists and focus it.
    local ready = h.wait(function()
      return h.lua(c, [[
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          local buf = vim.api.nvim_win_get_buf(win)
          if vim.bo[buf].filetype:match("snacks") then
            vim.api.nvim_set_current_win(win)
            return true
          end
        end
        return false
      ]])
    end, 5000)
    assert(ready, "snacks picker did not open")

    -- Confirm the selected entry; config maps <CR> -> "tab" action.
    h.input(c, "<CR>")

    -- A second tab must appear.
    local tabs = h.wait(function()
      local n = h.lua(c, "return vim.fn.tabpagenr('$')")
      return n and n > 1 and n
    end, 3000)
    assert(tabs, "no new tab after <CR> in snacks explorer (tab count stayed at 1)")
  end)
end

return T
