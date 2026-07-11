local h = require("helpers")

-- Each test spawns its own child nvim and tears it down.
local function with_child(fn)
	local c = h.start_child()
	local ok, err = pcall(fn, c)
	h.stop(c)
	if not ok then
		error(err, 0)
	end
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

local function on_ssh()
	return (vim.env.SSH_TTY or vim.env.SSH_CONNECTION) ~= nil
end

-- Outside SSH, clipboard=unnamedplus makes every yank/delete/paste use the
-- system clipboard (xclip/wl-copy) automatically -- fine there since Get()
-- is a fast, non-interactive subprocess call.
T["clipboard option is set to unnamedplus (non-SSH)"] = function()
	if on_ssh() then
		return
	end
	with_child(function(c)
		assert(h.lua(c, "return vim.o.clipboard") == "unnamedplus", "clipboard option not unnamedplus")
	end)
end

-- Over SSH, clipboard must stay unset (NOT unnamedplus): aliasing "" to "+
-- would make every plain yank/delete/paste transparently read through "+,
-- which under OSC 52 blocks up to 10s waiting for a terminal response (see
-- vim/ui/clipboard/osc52.lua). Plain yy/dd/p must stay purely internal.
T["clipboard is left unaliased over SSH (plain yanks stay internal)"] = function()
	if not on_ssh() then
		return
	end
	with_child(function(c)
		local clip = h.lua(c, "return vim.o.clipboard")
		assert(clip == "", "clipboard should be empty under SSH, got: " .. vim.inspect(clip))
	end)
end

-- Over SSH there's no display on the remote host, so options.lua switches to
-- OSC 52 (writes through the terminal escape sequence, no xclip/wl-copy needed).
T["uses OSC 52 clipboard provider over SSH"] = function()
	if not on_ssh() then
		return
	end
	with_child(function(c)
		local name = h.lua(c, "return vim.g.clipboard and vim.g.clipboard.name")
		assert(name == "OSC 52", "expected OSC 52 provider under SSH, got: " .. vim.inspect(name))
	end)
end

-- Explicit "+yy must complete without blocking: copy() only fires the OSC 52
-- escape sequence, it doesn't wait for a response (only paste() does). If
-- this hangs, the child never replies and h.lua below times out the test.
T['explicit "+y does not block under SSH (copy is fire-and-forget)'] = function()
	if not on_ssh() then
		return
	end
	with_child(function(c)
		h.input(c, 'ihello osc52<Esc>0"+yy')
		local line = h.lua(c, "return vim.api.nvim_get_current_line()")
		assert(line == "hello osc52", 'unexpected buffer state after "+yy: ' .. vim.inspect(line))
	end)
end

-- Outside SSH, with clipboard=unnamedplus, ordinary yanks must mirror into
-- the "+" register (works even without a functional OS clipboard/DISPLAY,
-- since nvim keeps "+ as a real addressable register regardless of provider
-- push). Skipped over SSH: OSC 52's paste() blocks up to 10s waiting for a
-- terminal response that a headless test runner will never send (see
-- vim/ui/clipboard/osc52.lua) -- getreg('+') would hang the whole suite.
T["yanking mirrors text into the + register (non-SSH)"] = function()
	if on_ssh() then
		return
	end
	with_child(function(c)
		h.input(c, "ihello clipboard<Esc>0yy")
		local plus = h.wait(function()
			local v = h.lua(c, "return vim.fn.getreg('+')")
			return v == "hello clipboard\n" and v or nil
		end, 2000)
		assert(plus, "+ register not synced from yank")
	end)
end

-- Real OS clipboard round-trip: requires an active X11/Wayland session and a
-- working clipboard tool (xclip/wl-copy), and NOT SSH (options.lua prefers
-- OSC 52 there, so this would be testing the wrong provider). Skipped
-- headless/CI where there's no DISPLAY, since the tool may exist on PATH but
-- can't reach a server.
T["yanked text reaches the real OS clipboard (requires DISPLAY, non-SSH)"] = function()
	if on_ssh() then
		return
	end
	if vim.env.DISPLAY == nil and vim.env.WAYLAND_DISPLAY == nil then
		return
	end
	with_child(function(c)
		local marker = "e2e-clipboard-check-" .. tostring(math.random(100000))
		h.input(c, "i" .. marker .. "<Esc>0yy")
		h.wait(function()
			return h.lua(c, "return vim.fn.getreg('+')") == marker .. "\n"
		end, 2000)
		local read_cmd = vim.env.WAYLAND_DISPLAY and "wl-paste" or "xclip -selection clipboard -o"
		local got = vim.fn.system(read_cmd)
		assert(got:match(marker), "OS clipboard missing yanked text: " .. vim.inspect(got))
	end)
end

-- Window-nav keymap from keymaps.lua exists.
T["registers <C-h> window-nav keymap"] = function()
	with_child(function(c)
		local found = h.lua(
			c,
			[[
      for _, m in ipairs(vim.api.nvim_get_keymap("n")) do
        if m.lhs == "<C-H>" then return true end
      end
      return false
    ]]
		)
		assert(found, "<C-h> not mapped")
	end)
end

-- Lazy installed and loaded the requested plugins.
T["lazy has the requested plugins"] = function()
	with_child(function(c)
		local names = h.lua(
			c,
			[[
      local out = {}
      for _, p in ipairs(require("lazy").plugins()) do out[p.name] = true end
      return out
    ]]
		)
		for _, want in ipairs({
			"which-key.nvim",
			"trouble.nvim",
			"snacks.nvim",
			"nvim-lspconfig",
			"mason.nvim",
			"catppuccin",
			"lualine.nvim",
			"blink.cmp",
			"telescope.nvim",
			"gitsigns.nvim",
			"conform.nvim",
			"flash.nvim",
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
			assert(h.lua(c, "return package.loaded[...] == nil", mod), mod .. " loaded at startup (should be lazy)")
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

-- Live Grep's <C-o>/<C-e> prompt for include/exclude paths and the picker
-- re-opens showing them (read-only) in its prompt title.
T["Telescope live_grep <C-o>/<C-e> filter paths and show them in the title"] = function()
	with_child(function(c)
		h.input(c, " fg")
		local opened = h.wait(function()
			return h.lua(c, "return vim.bo.buftype") == "prompt"
		end, 5000)
		assert(opened, "live_grep prompt did not open")

		local function current_title()
			return h.lua(
				c,
				[[
        local ok, picker = pcall(
          require("telescope.actions.state").get_current_picker,
          vim.api.nvim_get_current_buf()
        )
        return ok and picker and picker.prompt_title or nil
      ]]
			)
		end
		assert(current_title() and current_title():find("?: <C-/>", 1, true), "got: " .. vim.inspect(current_title()))

		-- <C-o>: restrict the search to specific paths.
		h.input(c, "<C-o>")
		local asking_include = h.wait(function()
			return h.lua(c, "return vim.api.nvim_get_mode().mode") == "c"
		end, 3000)
		assert(asking_include, "<C-o> did not open an input prompt")
		h.input(c, "lua/plugins, lua/config<CR>")
		local include_title = h.wait(function()
			local t = current_title()
			return t ~= nil and t:find("in: lua/plugins, lua/config", 1, true) and t
		end, 3000)
		assert(include_title, "title missing include paths, got: " .. vim.inspect(current_title()))

		-- <C-e>: additionally exclude a path; both filters must show together.
		h.input(c, "<C-e>")
		local asking_exclude = h.wait(function()
			return h.lua(c, "return vim.api.nvim_get_mode().mode") == "c"
		end, 3000)
		assert(asking_exclude, "<C-e> did not open an input prompt")
		h.input(c, "lua/config<CR>")
		local final_title = h.wait(function()
			local t = current_title()
			return t ~= nil
				and t:find("in: lua/plugins, lua/config", 1, true)
				and t:find("not in: lua/config", 1, true)
				and t
		end, 3000)
		assert(final_title, "title missing exclude path, got: " .. vim.inspect(current_title()))

		h.input(c, "<Esc>")
	end)
end

-- <C-/> (Telescope's built-in which-key trigger, hinted by the "?" in the
-- prompt title) must list the custom <C-o>/<C-e> path-filter shortcuts.
T["Telescope live_grep <C-/> shows the path-filter shortcuts in which-key"] = function()
	with_child(function(c)
		h.input(c, " fg")
		assert(h.wait(function()
			return h.lua(c, "return vim.bo.buftype")
		end, 5000) == "prompt", "live_grep prompt did not open")

		h.input(c, "<C-/>")
		local opened = h.wait(function()
			return h.lua(
				c,
				[[
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_get_name(buf):find("_TelescopeWhichKey", 1, true) then
            return true
          end
        end
        return false
      ]]
			)
		end, 3000)
		assert(opened, "<C-/> did not open the which-key popup")

		local has_shortcuts = h.lua(
			c,
			[[
      local found_o, found_e = false, false
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local name = vim.api.nvim_buf_get_name(buf)
        if name:find("_TelescopeWhichKey", 1, true) and not name:find("Border", 1, true) then
          for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
            if line:find("Live Grep: only in paths", 1, true) then found_o = true end
            if line:find("Live Grep: exclude paths", 1, true) then found_e = true end
          end
        end
      end
      return found_o and found_e
    ]]
		)
		assert(has_shortcuts, "which-key popup missing the <C-o>/<C-e> path-filter entries")
	end)
end

-- Re-entering Live Grep (a fresh <leader>fg, not <C-o>/<C-e>) must reapply
-- the last query text and path filters instead of starting empty.
T["Telescope live_grep reapplies last query and filters on re-entry"] = function()
	with_child(function(c)
		local function current_title()
			return h.lua(
				c,
				[[
        local ok, picker = pcall(
          require("telescope.actions.state").get_current_picker,
          vim.api.nvim_get_current_buf()
        )
        return ok and picker and picker.prompt_title or nil
      ]]
			)
		end
		local function prompt_text()
			-- The buffer line includes the literal prompt_prefix (e.g. "> ");
			-- strip it the same way Telescope's own Picker:_get_prompt() does.
			return h.lua(
				c,
				[[
        local picker = require("telescope.actions.state").get_current_picker(vim.api.nvim_get_current_buf())
        local line = vim.api.nvim_get_current_line()
        return picker and line:sub(#picker.prompt_prefix + 1) or line
      ]]
			)
		end

		h.input(c, " fg")
		assert(h.wait(function()
			return h.lua(c, "return vim.bo.buftype")
		end, 5000) == "prompt", "live_grep prompt did not open")

		-- Set an include filter.
		h.input(c, "<C-o>")
		assert(h.wait(function()
			return h.lua(c, "return vim.api.nvim_get_mode().mode")
		end, 3000) == "c", "<C-o> did not open an input prompt")
		h.input(c, "lua/plugins<CR>")
		assert(
			h.wait(function()
				local t = current_title()
				return t ~= nil and t:find("in: lua/plugins", 1, true) and t
			end, 3000),
			"include filter not applied"
		)

		-- The <C-o> flow closes and re-opens the picker; give it a beat to land
		-- back in insert mode before typing (closing+reopening is not instant).
		assert(
			h.wait(function()
				return h.lua(c, "return vim.api.nvim_get_mode().mode"):match("^i") and true or nil
			end, 3000),
			"not back in insert mode after <C-o>"
		)

		-- Type a query, then close the picker outright (<C-c>, mapped to close
		-- directly from insert mode) -- not just leave insert mode.
		h.input(c, "needle")
		assert(
			h.wait(function()
				return prompt_text() == "needle"
			end, 3000),
			"query text not typed"
		)
		h.input(c, "<C-c>")
		assert(
			h.wait(function()
				return h.lua(c, "return vim.bo.buftype") ~= "prompt"
			end, 3000),
			"live_grep prompt did not close"
		)

		-- Re-enter Live Grep from scratch: text + include filter must both persist.
		h.input(c, " fg")
		assert(h.wait(function()
			return h.lua(c, "return vim.bo.buftype")
		end, 5000) == "prompt", "live_grep did not re-open")
		local reopened_title = h.wait(function()
			local t = current_title()
			return t ~= nil and t:find("in: lua/plugins", 1, true) and t
		end, 3000)
		assert(reopened_title, "include filter lost on re-entry, got: " .. vim.inspect(current_title()))
		local reopened_text = h.wait(function()
			local t = prompt_text()
			return t == "needle" and t
		end, 3000)
		assert(reopened_text, "query text lost on re-entry, got: " .. vim.inspect(prompt_text()))

		h.input(c, "<C-c>")
	end)
end

-- <C-g> clears the query text and both path filters, reopening a fresh
-- search -- and that cleared state must stick on the next <leader>fg too
-- (not just for the picker instance <C-g> was pressed in).
T["Telescope live_grep <C-g> clears query and filters, and it sticks"] = function()
	with_child(function(c)
		local function current_title()
			return h.lua(
				c,
				[[
        local ok, picker = pcall(
          require("telescope.actions.state").get_current_picker,
          vim.api.nvim_get_current_buf()
        )
        return ok and picker and picker.prompt_title or nil
      ]]
			)
		end
		local function prompt_text()
			return h.lua(
				c,
				[[
        local picker = require("telescope.actions.state").get_current_picker(vim.api.nvim_get_current_buf())
        local line = vim.api.nvim_get_current_line()
        return picker and line:sub(#picker.prompt_prefix + 1) or line
      ]]
			)
		end
		local function wait_insert()
			return h.wait(function()
				return h.lua(c, "return vim.api.nvim_get_mode().mode"):match("^i") and true or nil
			end, 3000)
		end

		h.input(c, " fg")
		assert(h.wait(function()
			return h.lua(c, "return vim.bo.buftype")
		end, 5000) == "prompt", "live_grep prompt did not open")

		-- Set both filters and type a query.
		h.input(c, "<C-o>")
		assert(h.wait(function()
			return h.lua(c, "return vim.api.nvim_get_mode().mode")
		end, 3000) == "c", "<C-o> did not open an input prompt")
		h.input(c, "lua/plugins<CR>")
		assert(
			h.wait(function()
				local t = current_title()
				return t ~= nil and t:find("in: lua/plugins", 1, true) and t
			end, 3000),
			"include filter not applied"
		)
		assert(wait_insert(), "not back in insert mode after <C-o>")

		h.input(c, "<C-e>")
		assert(h.wait(function()
			return h.lua(c, "return vim.api.nvim_get_mode().mode")
		end, 3000) == "c", "<C-e> did not open an input prompt")
		h.input(c, "lua/config<CR>")
		assert(
			h.wait(function()
				local t = current_title()
				return t ~= nil and t:find("not in: lua/config", 1, true) and t
			end, 3000),
			"exclude filter not applied"
		)
		assert(wait_insert(), "not back in insert mode after <C-e>")

		h.input(c, "needle")
		assert(
			h.wait(function()
				return prompt_text() == "needle"
			end, 3000),
			"query text not typed"
		)

		-- Clear everything.
		h.input(c, "<C-g>")
		assert(wait_insert(), "not back in insert mode after <C-g>")
		local cleared_title = h.wait(function()
			local t = current_title()
			return t ~= nil and not t:find("in:", 1, true) and t
		end, 3000)
		assert(cleared_title, "filters not cleared, got: " .. vim.inspect(current_title()))
		local cleared_text = h.wait(function()
			local t = prompt_text()
			return t == "" and t or nil
		end, 3000)
		assert(cleared_text ~= nil, "query text not cleared, got: " .. vim.inspect(prompt_text()))

		-- Close outright, then re-enter: the cleared state must persist too.
		h.input(c, "<C-c>")
		assert(
			h.wait(function()
				return h.lua(c, "return vim.bo.buftype") ~= "prompt"
			end, 3000),
			"live_grep prompt did not close"
		)
		h.input(c, " fg")
		assert(h.wait(function()
			return h.lua(c, "return vim.bo.buftype")
		end, 5000) == "prompt", "live_grep did not re-open")
		local reopened_title = h.wait(function()
			local t = current_title()
			return t ~= nil and not t:find("in:", 1, true) and t
		end, 3000)
		assert(reopened_title, "cleared filters did not persist, got: " .. vim.inspect(current_title()))
		local reopened_text = h.wait(function()
			local t = prompt_text()
			return t == "" and t or nil
		end, 3000)
		assert(reopened_text ~= nil, "cleared query did not persist, got: " .. vim.inspect(prompt_text()))

		h.input(c, "<C-c>")
	end)
end

-- Find Files gets the same <C-o>/<C-e>/<C-g> filters, "?" which-key hint,
-- and cross-invocation persistence as Live Grep (shared `make_filterable_opener`).
T["Telescope find_files <C-o>/<C-e> filter paths, show them in the title, persist on re-entry"] = function()
	with_child(function(c)
		local function current_title()
			return h.lua(
				c,
				[[
        local ok, picker = pcall(
          require("telescope.actions.state").get_current_picker,
          vim.api.nvim_get_current_buf()
        )
        return ok and picker and picker.prompt_title or nil
      ]]
			)
		end

		h.input(c, " ff")
		assert(h.wait(function()
			return h.lua(c, "return vim.bo.buftype")
		end, 5000) == "prompt", "find_files prompt did not open")
		assert(current_title() and current_title():find("?: <C-/>", 1, true), "got: " .. vim.inspect(current_title()))

		-- <C-o>: restrict the search to specific paths.
		h.input(c, "<C-o>")
		assert(h.wait(function()
			return h.lua(c, "return vim.api.nvim_get_mode().mode")
		end, 3000) == "c", "<C-o> did not open an input prompt")
		h.input(c, "lua/plugins<CR>")
		assert(
			h.wait(function()
				local t = current_title()
				return t ~= nil and t:find("in: lua/plugins", 1, true) and t
			end, 3000),
			"include filter not applied"
		)

		-- <C-e>: additionally exclude a path; both filters must show together.
		h.input(c, "<C-e>")
		assert(h.wait(function()
			return h.lua(c, "return vim.api.nvim_get_mode().mode")
		end, 3000) == "c", "<C-e> did not open an input prompt")
		h.input(c, "lua/config<CR>")
		local final_title = h.wait(function()
			local t = current_title()
			return t ~= nil and t:find("in: lua/plugins", 1, true) and t:find("not in: lua/config", 1, true) and t
		end, 3000)
		assert(final_title, "title missing exclude path, got: " .. vim.inspect(current_title()))

		-- Close outright, then re-enter: both filters must persist.
		h.input(c, "<C-c>")
		assert(
			h.wait(function()
				return h.lua(c, "return vim.bo.buftype") ~= "prompt"
			end, 3000),
			"find_files prompt did not close"
		)
		h.input(c, " ff")
		local reopened_title = h.wait(function()
			local t = current_title()
			return t ~= nil and t:find("in: lua/plugins", 1, true) and t:find("not in: lua/config", 1, true) and t
		end, 5000)
		assert(reopened_title, "filters did not persist on re-entry, got: " .. vim.inspect(current_title()))

		-- <C-g>: clear back to a blank search.
		h.input(c, "<C-g>")
		local cleared_title = h.wait(function()
			local t = current_title()
			return t ~= nil and not t:find("in:", 1, true) and t
		end, 3000)
		assert(cleared_title, "filters not cleared, got: " .. vim.inspect(current_title()))

		h.input(c, "<C-c>")
	end)
end

-- The custom find_command used to implement <C-e> for find_files (plain
-- ripgrep has no built-in "exclude path" flag for --files, unlike the
-- glob_pattern support live_grep gets natively) must actually filter results,
-- not just update the title.
T["Telescope find_files <C-e> actually excludes matching files from results"] = function()
	with_child(function(c)
		local dir = h.lua(
			c,
			[[
      local d = vim.fn.tempname()
      vim.fn.mkdir(d .. "/keep", "p")
      vim.fn.mkdir(d .. "/skip", "p")
      local function put(path)
        local f = assert(io.open(path, "w"))
        f:write("x\n")
        f:close()
      end
      put(d .. "/keep/a.txt")
      put(d .. "/skip/b.txt")
      return d
    ]]
		)
		h.lua(c, "vim.cmd.cd(...)", dir)

		h.input(c, " ff")
		assert(h.wait(function()
			return h.lua(c, "return vim.bo.buftype")
		end, 5000) == "prompt", "find_files prompt did not open")

		h.input(c, "<C-e>")
		assert(h.wait(function()
			return h.lua(c, "return vim.api.nvim_get_mode().mode")
		end, 3000) == "c", "<C-e> did not open an input prompt")
		h.input(c, "skip<CR>")
		local function current_title()
			return h.lua(
				c,
				[[
        local ok, picker = pcall(
          require("telescope.actions.state").get_current_picker,
          vim.api.nvim_get_current_buf()
        )
        return ok and picker and picker.prompt_title or nil
      ]]
			)
		end
		assert(
			h.wait(function()
				local t = current_title()
				return t ~= nil and t:find("not in: skip", 1, true) and t
			end, 3000),
			"exclude filter not applied"
		)

		local function results_text()
			return h.lua(
				c,
				[[
        local picker = require("telescope.actions.state").get_current_picker(vim.api.nvim_get_current_buf())
        return table.concat(vim.api.nvim_buf_get_lines(picker.results_bufnr, 0, -1, false), "\n")
      ]]
			)
		end

		local kept = h.wait(function()
			local t = results_text()
			return t:find("a.txt", 1, true) and t
		end, 5000)
		assert(kept, "expected keep/a.txt in results, got: " .. vim.inspect(results_text()))
		assert(not results_text():find("b.txt", 1, true), "skip/b.txt was not excluded from results")

		h.input(c, "<C-c>")
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
			return h.lua(
				c,
				[[
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
      ]]
			)
		end, 30000, 500)
		assert(hover, "rust_analyzer returned no hover")
	end)
end

-- Full LSP chain E2E: open a PHP file, intelephense attaches.
T["intelephense attaches (LSP E2E)"] = function()
	with_child(function(c)
		local dir = h.make_php_project()
		h.lua(c, "vim.cmd.edit(...)", dir .. "/index.php")

		local attached = h.wait(function()
			return h.lua(c, "return #vim.lsp.get_clients({ name = 'intelephense' }) > 0")
		end, 30000, 200)
		assert(attached, "intelephense did not attach")
	end)
end

-- GDScript's LSP is the running Godot editor (TCP 127.0.0.1:6005), not a Mason
-- binary, so a live attach can't run in CI without Godot open. Assert the client
-- is registered and enabled: TCP cmd (rpc.connect returns a function) and
-- project.godot as a root marker. If this regresses, .gd buffers get no LSP.
T["gdscript LSP client is configured and enabled"] = function()
	with_child(function(c)
		-- nvim-lspconfig lazy-loads on BufReadPre/BufNewFile; force it so the
		-- config block (which registers gdscript) has run.
		h.lua(c, "require('lazy').load({ plugins = { 'nvim-lspconfig' } })")
		local cmd_type = h.lua(c, "return type(vim.lsp.config.gdscript.cmd)")
		assert(cmd_type == "function", "gdscript cmd is not a TCP connect function")
		local marker = h.lua(c, "return vim.tbl_contains(vim.lsp.config.gdscript.root_markers, 'project.godot')")
		assert(marker, "gdscript root_markers missing project.godot")
		assert(h.lua(c, "return vim.lsp.is_enabled('gdscript')"), "gdscript not enabled")
	end)
end

-- Regression test: nvim-treesitter's `main` branch was reinstalled after
-- orphaned parser binaries (leftover from the removed `master` branch) were
-- found silently disabling ALL highlighting for languages with no matching
-- query -- PHP, Go, Rust, Python, YAML, JSON, HTML, TOML, CSS/SCSS included.
-- `vim.treesitter.start()` succeeds (parser present) which turns OFF legacy
-- regex `syntax`, but with no query it renders nothing. Assert real captures
-- come back for a representative sample; extmarks stay empty in headless
-- mode with no UI attached, so query captures are the only reliable signal.
T["treesitter highlights previously-broken filetypes"] = function()
	with_child(function(c)
		local samples = {
			{ ft = "php", body = { "<?php", '$name = "world";' }, row = 1, col = 1 },
			{ ft = "go", body = { "package main" }, row = 0, col = 1 },
			{ ft = "python", body = { "def f():", "    pass" }, row = 0, col = 1 },
			{ ft = "yaml", body = { "key: value" }, row = 0, col = 0 },
		}
		for _, s in ipairs(samples) do
			h.lua(
				c,
				[[
        vim.cmd.enew()
        vim.bo.filetype = ...
      ]],
				s.ft
			)
			h.lua(c, "vim.api.nvim_buf_set_lines(0, 0, -1, false, ...)", s.body)
			-- run.sh waits for all parsers to finish compiling before the suite
			-- starts (see its "Waiting for treesitter parsers" step), so this only
			-- needs to tolerate normal scheduling jitter, not a cold compile.
			local caps = h.wait(function()
				local n = h.lua(c, "return #vim.treesitter.get_captures_at_pos(0, ..., ...)", s.row, s.col)
				return n > 0 and n
			end, 15000, 100)
			assert(caps, s.ft .. ": expected treesitter captures, got none")
		end
	end)
end

-- Real autocomplete E2E: minuet -> Ollama FIM -> inline ghost text appears.
-- Gated behind $MINUET_E2E so the normal suite doesn't need the docker server
-- running. The `run-autocomplete.sh` wrapper sets it after the container is up.
T["minuet produces inline ghost text (autocomplete E2E)"] = function()
	if vim.env.MINUET_E2E ~= "1" then
		return
	end -- skipped unless server is up
	with_child(function(c)
		-- Reproduce REAL usage ordering: set filetype BEFORE minuet loads (it's
		-- InsertEnter-lazy), so minuet's own FileType autocmd misses this buffer.
		-- Without the manual-arm fix in minuet.lua, auto-trigger stays off and no
		-- ghost text ever appears. Do NOT pre-load or pre-arm minuet here.
		h.lua(
			c,
			[[
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
    ]]
		)
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
			return h.lua(
				c,
				[[
        for _, m in ipairs(vim.api.nvim_get_keymap("i")) do
          if m.lhs == "<M-C>" then return true end
        end
        return false
      ]]
			)
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
		local found = h.lua(
			c,
			[[
      return #vim.api.nvim_get_autocmds({
        event = "User", pattern = "MinuetRequestStarted",
      }) > 0
    ]]
		)
		assert(found, "no listener for MinuetRequestStarted (status indicator missing)")
	end)
end

-- Snacks explorer <CR> must open files in a new tab (not the current buffer).
T["snacks explorer <CR> opens file in new tab"] = function()
	with_child(function(c)
		assert(h.lua(c, "return package.loaded['snacks'] ~= nil"), "snacks not loaded")

		-- Pre-open a file so the original window isn't an empty unnamed buffer.
		-- Without this, snacks suppresses new-tab creation (it avoids opening a tab
		-- when the only non-floating window holds a blank buffer).
		h.lua(c, "vim.cmd.edit(...)", "tests/helpers.lua")

		-- Write a temp file so the explorer has something to confirm on.
		local tmpfile = h.lua(
			c,
			[[
      local path = vim.fn.tempname() .. ".lua"
      local fh = assert(io.open(path, "w"))
      fh:write("return {}\n")
      fh:close()
      return path
    ]]
		)
		local tmpdir = h.lua(c, "return vim.fn.fnamemodify(..., ':h')", tmpfile)

		-- Open explorer at the temp dir.
		h.lua(c, "require('snacks').picker.explorer({ cwd = ... })", tmpdir)

		-- Wait until a snacks picker window exists and focus it.
		local ready = h.wait(function()
			return h.lua(
				c,
				[[
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          local buf = vim.api.nvim_win_get_buf(win)
          if vim.bo[buf].filetype:match("snacks") then
            vim.api.nvim_set_current_win(win)
            return true
          end
        end
        return false
      ]]
			)
		end, 5000)
		assert(ready, "snacks picker did not open")

		-- Wait for items, then navigate to the first file item.
		-- The explorer's first item is always the root directory node;
		-- pressing <CR> on a dir only toggles expand, not open-in-tab.
		-- We use the picker API to move past directory items to the file.
		local on_file = h.wait(function()
			return h.lua(
				c,
				[[
        local ok, pickers = pcall(function() return require('snacks.picker').get() end)
        if not ok or #pickers == 0 then return false end
        local p = pickers[1]
        if p:count() == 0 then return false end
        -- move down until we land on a non-directory item
        local item = p:current()
        if item and item.dir then
          p.list:move(1)
          item = p:current()
        end
        return item ~= nil and not item.dir
      ]]
			)
		end, 3000)
		assert(on_file, "could not find a file item in snacks explorer")

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

-- markdown-prettier-warn: unit-tested directly in the parent process (no child needed).
local function load_md_warn()
	package.path = vim.fn.getcwd() .. "/lua/?.lua;" .. package.path
	package.loaded["methods.markdown-prettier-warn"] = nil
	return require("methods.markdown-prettier-warn")
end

T["markdown prettier warn: fires once when prettier absent"] = function()
	local m = load_md_warn()
	local count = 0
	local absent = function(_)
		return false
	end
	local notify = function(_, _)
		count = count + 1
	end
	m.check(0, absent, notify)
	m.check(0, absent, notify)
	m.check(0, absent, notify)
	assert(count == 1, "expected 1 warning, got " .. count)
end

T["markdown prettier warn: silent when prettier present"] = function()
	local m = load_md_warn()
	local count = 0
	local present = function(_)
		return true
	end
	local notify = function(_, _)
		count = count + 1
	end
	m.check(0, present, notify)
	m.check(0, present, notify)
	assert(count == 0, "expected 0 warnings, got " .. count)
end

T["markdown prettier warn: stays silent after first-warn suppression"] = function()
	local m = load_md_warn()
	local count = 0
	local notify = function(_, _)
		count = count + 1
	end
	m.check(0, function(_)
		return false
	end, notify) -- fires
	m.check(0, function(_)
		return false
	end, notify) -- suppressed
	m.check(0, function(_)
		return true
	end, notify) -- suppressed (already warned)
	assert(count == 1, "expected 1 warning, got " .. count)
end

-- The error gate is dependency-injected, so test its logic directly in the
-- parent (no child / no systemd needed). Load the module from the config.
local function load_gate()
	package.path = vim.fn.getcwd() .. "/lua/?.lua;" .. package.path
	package.loaded["methods.minuet_error_gate"] = nil
	return require("methods.minuet_error_gate")
end

-- Service DOWN: prompt fires once, errors are swallowed (no spam).
T["error gate: prompts once and swallows while service is down"] = function()
	local gate_mod = load_gate()
	local prompts, emits = 0, 0
	local clock = 0
	local gate = gate_mod.new(
		function(cb)
			cb(false)
		end, -- always down
		function()
			prompts = prompts + 1
		end,
		{
			now = function()
				return clock
			end,
		}
	)
	for _ = 1, 5 do
		gate(function()
			emits = emits + 1
		end)
		clock = clock + 1000 -- 1s apart, all within the 30s window
	end
	assert(prompts == 1, "expected 1 prompt, got " .. prompts)
	assert(emits == 0, "expected no errors shown while down, got " .. emits)
end

-- Service UP: errors pass through every time, no prompt.
T["error gate: shows errors when service is up"] = function()
	local gate_mod = load_gate()
	local prompts, emits = 0, 0
	local clock = 0
	local gate = gate_mod.new(
		function(cb)
			cb(true)
		end, -- always up
		function()
			prompts = prompts + 1
		end,
		{
			now = function()
				return clock
			end,
		}
	)
	for _ = 1, 3 do
		gate(function()
			emits = emits + 1
		end)
		clock = clock + 1000
	end
	assert(prompts == 0, "expected no prompt when up, got " .. prompts)
	assert(emits == 3, "expected all 3 errors shown, got " .. emits)
end

-- Service is only re-probed at most once per 30s; within the window the cached
-- state is reused (no extra probes).
T["error gate: re-checks service at most once per 30s"] = function()
	local gate_mod = load_gate()
	local checks = 0
	local clock = 0
	local gate = gate_mod.new(function(cb)
		checks = checks + 1
		cb(false)
	end, function() end, {
		now = function()
			return clock
		end,
	})
	gate(function() end) -- t=0: probes
	clock = 10000
	gate(function() end) -- t=10s: cached, no probe
	clock = 29000
	gate(function() end) -- t=29s: cached, no probe
	assert(checks == 1, "expected 1 probe within 30s, got " .. checks)
	clock = 31000
	gate(function() end) -- t=31s: window elapsed, probes again
	assert(checks == 2, "expected re-probe after 30s, got " .. checks)
end

-- Recovery: service comes back up, then drops again -> prompt fires a 2nd time.
T["error gate: re-arms prompt after the service recovers"] = function()
	local gate_mod = load_gate()
	local prompts = 0
	local clock, up = 0, false
	local gate = gate_mod.new(function(cb)
		cb(up)
	end, function()
		prompts = prompts + 1
	end, {
		now = function()
			return clock
		end,
	})
	gate(function() end) -- down -> prompt #1
	clock = clock + 31000
	up = true
	gate(function() end) -- up -> emits, re-arms
	clock = clock + 31000
	up = false
	gate(function() end) -- down again -> prompt #2
	assert(prompts == 2, "expected prompt to re-arm after recovery, got " .. prompts)
end

-- mermaid-live: pure parsing + URL encoding, tested directly in parent.
local function load_mermaid()
	package.path = vim.fn.getcwd() .. "/lua/?.lua;" .. package.path
	package.loaded["methods.mermaid-live"] = nil
	return require("methods.mermaid-live")
end

T["mermaid-live: extracts the block the cursor sits in"] = function()
	local m = load_mermaid()
	local lines = { "# doc", "```mermaid", "flowchart TD", "  A --> B", "```", "after" }
	assert(m.block_at(lines, 3) == "flowchart TD\n  A --> B", "body extraction")
	assert(m.block_at(lines, 2) == "flowchart TD\n  A --> B", "fence line counts as inside")
	assert(m.block_at(lines, 1) == nil, "outside block -> nil")
	assert(m.block_at(lines, 6) == nil, "after block -> nil")
end

T["mermaid-live: ignores non-mermaid fences"] = function()
	local m = load_mermaid()
	local lines = { "```lua", "print(1)", "```" }
	assert(m.block_at(lines, 2) == nil, "lua fence must not match")
end

T["mermaid-live: URL round-trips the code via base64 state"] = function()
	local m = load_mermaid()
	local url = m.encode_url("flowchart TD\n  A --> B")
	local b64 = url:match("#base64:(.+)$")
	assert(b64, "url has base64 fragment: " .. url)
	local state = vim.json.decode(vim.base64.decode(b64))
	assert(state.code == "flowchart TD\n  A --> B", "decoded code mismatch")
end

T["mermaid-live: places one hint extmark per mermaid fence"] = function()
	local m = load_mermaid()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
		"```mermaid",
		"flowchart TD",
		"```",
		"```lua",
		"print(1)",
		"```",
		"```mermaid",
		"graph LR",
		"```",
	})
	m.refresh_hints(buf)
	local ns = vim.api.nvim_get_namespaces()["mermaid-live-hint"]
	local marks = vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {})
	assert(#marks == 2, "expected 2 hints (mermaid fences only), got " .. #marks)
end

-- nvim-dap loads on a gdscript buffer, wires the Godot adapter, and the
-- breakpoint hotkey places a red-circle sign in the gutter.
T["dap: godot adapter loads on gdscript and toggle places a breakpoint sign"] = function()
	with_child(function(c)
		h.lua(c, "vim.cmd('enew'); vim.bo.filetype = 'gdscript'")
		local loaded = h.wait(function()
			return h.lua(c, "return package.loaded['dap'] ~= nil")
		end)
		assert(loaded, "nvim-dap did not load on gdscript ft")

		assert(h.lua(c, "return require('dap').adapters.godot.port") == 6006, "godot adapter port")
		assert(h.lua(c, "return require('dap').configurations.gdscript[1].type") == "godot", "gdscript config type")

		local sign = h.lua(c, "return vim.fn.sign_getdefined('DapBreakpoint')[1].text")
		assert(sign and sign:find("●"), "breakpoint sign text, got: " .. vim.inspect(sign))

		-- The <leader>db hotkey toggles a breakpoint -> a sign gets placed.
		h.input(c, " db")
		local placed = h.wait(function()
			return h.lua(c, "return #(vim.fn.sign_getplaced(0, {group='*'})[1].signs) > 0")
		end)
		assert(placed, "breakpoint hotkey did not place a sign")
	end)
end

return T
