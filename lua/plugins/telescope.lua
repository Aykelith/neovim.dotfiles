-- Fuzzy finder. Lazy: command + keys only. fzf-native compiled for speed.

--- Splits a comma-separated string into a trimmed, non-empty list.
local function split_csv(input)
	local list = {}
	for part in string.gmatch(input or "", "([^,]+)") do
		local trimmed = vim.trim(part)
		if trimmed ~= "" then
			table.insert(list, trimmed)
		end
	end
	return list
end

--- Builds the prompt title shown above a filterable picker's prompt: a
--- permanent "?" hint pointing at Telescope's which-key popup (<C-/>,
--- unchanged -- binding literal "?" would break typing "?" into a query),
--- plus the active include/exclude path filters (read-only: it's a window
--- border title, not an editable field).
local function filter_title(display_name, include_dirs, exclude_dirs)
	local parts = { "?: <C-/>" }
	if include_dirs and #include_dirs > 0 then
		table.insert(parts, "in: " .. table.concat(include_dirs, ", "))
	end
	if exclude_dirs and #exclude_dirs > 0 then
		table.insert(parts, "not in: " .. table.concat(exclude_dirs, ", "))
	end
	return display_name .. " [" .. table.concat(parts, " | ") .. "]"
end

--- `find_files` has no `glob_pattern` support (unlike `live_grep`), so
--- excludes are done via a custom `find_command` (ripgrep-only, matching
--- the ripgrep-only glob support live_grep already relies on).
local function find_files_exclude_command(exclude_dirs)
	return function()
		local cmd = { "rg", "--files", "--color", "never" }
		for _, dir in ipairs(exclude_dirs) do
			table.insert(cmd, "--glob=!" .. dir)
		end
		return cmd
	end
end

--- Factory: builds an `open` function for a filterable Telescope picker
--- (Live Grep, Find Files, ...) supporting:
---   - <C-o>/<C-e>: prompt for comma-separated paths to search only in /
---     exclude, shown read-only in the prompt title.
---   - <C-g>: clear the query text and both path filters.
---   - <C-/>: Telescope's built-in which-key popup, hinted by "?" in the
---     title, listing the above with readable names.
---   - Persistence of the last query text and both filters across separate
---     invocations (not just <C-o>/<C-e> re-opens within one session), so
---     re-opening resumes where the picker last left off.
--- `build_picker_opts(include_dirs, exclude_dirs)` returns the
--- picker-specific opts (e.g. `search_dirs`/`glob_pattern` for live_grep,
--- `search_dirs`/`find_command` for find_files).
local function make_filterable_opener(display_name, builtin_name, build_picker_opts)
	local last_search = { text = nil, include_dirs = nil, exclude_dirs = nil }

	local open
	open = function(include_dirs, exclude_dirs, default_text)
		local builtin = require("telescope.builtin")
		local actions = require("telescope.actions")
		local action_state = require("telescope.actions.state")

		last_search.include_dirs = include_dirs
		last_search.exclude_dirs = exclude_dirs
		last_search.text = default_text

		local picker_opts = build_picker_opts(include_dirs, exclude_dirs)
		picker_opts.default_text = default_text
		picker_opts.prompt_title = filter_title(display_name, include_dirs, exclude_dirs)
		picker_opts.attach_mappings = function(prompt_bufnr, map)
			-- Keep last_search.text current on every keystroke so it survives
			-- however the picker closes (Esc, selecting a result, <C-o>/<C-e>...).
			-- The prompt buffer's line includes the literal prompt_prefix (e.g.
			-- "> "), so strip it the same way Picker:_get_prompt() does.
			vim.api.nvim_create_autocmd({ "TextChangedI", "TextChanged" }, {
				buffer = prompt_bufnr,
				callback = function()
					local picker = action_state.get_current_picker(prompt_bufnr)
					local line = vim.api.nvim_buf_get_lines(prompt_bufnr, 0, 1, false)[1] or ""
					last_search.text = line:sub(#picker.prompt_prefix + 1)
				end,
			})
			map("i", "<C-o>", function(bufnr)
				local current_text = action_state.get_current_line()
				actions.close(bufnr)
				local input = vim.fn.input({
					prompt = display_name .. ": search only in paths (comma separated): ",
					default = table.concat(include_dirs or {}, ", "),
				})
				open(split_csv(input), exclude_dirs, current_text)
			end, { desc = display_name .. ": only in paths" })
			map("i", "<C-e>", function(bufnr)
				local current_text = action_state.get_current_line()
				actions.close(bufnr)
				local input = vim.fn.input({
					prompt = display_name .. ": exclude paths (comma separated): ",
					default = table.concat(exclude_dirs or {}, ", "),
				})
				open(include_dirs, split_csv(input), current_text)
			end, { desc = display_name .. ": exclude paths" })
			map("i", "<C-g>", function(bufnr)
				actions.close(bufnr)
				open(nil, nil, nil)
			end, { desc = display_name .. ": clear" })
			return true
		end

		builtin[builtin_name](picker_opts)
	end

	-- What `<leader>f?` should call: resume with whatever was last used.
	return function()
		open(last_search.include_dirs, last_search.exclude_dirs, last_search.text)
	end
end

local open_live_grep = make_filterable_opener("Live Grep", "live_grep", function(include_dirs, exclude_dirs)
	local glob_pattern = nil
	if exclude_dirs and #exclude_dirs > 0 then
		glob_pattern = {}
		for _, dir in ipairs(exclude_dirs) do
			table.insert(glob_pattern, "!" .. dir)
		end
	end
	return {
		search_dirs = (include_dirs and #include_dirs > 0) and include_dirs or nil,
		glob_pattern = glob_pattern,
	}
end)

local open_find_files = make_filterable_opener("Find Files", "find_files", function(include_dirs, exclude_dirs)
	return {
		search_dirs = (include_dirs and #include_dirs > 0) and include_dirs or nil,
		find_command = (exclude_dirs and #exclude_dirs > 0) and find_files_exclude_command(exclude_dirs) or nil,
	}
end)

return {
	"nvim-telescope/telescope.nvim",
	commit = "427b576c16792edad01a92b89721d923c19ad60f",
	cmd = "Telescope",
	dependencies = {
		{ "nvim-lua/plenary.nvim", commit = "74b06c6c75e4eeb3108ec01852001636d85a932b" },
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			commit = "b25b749b9db64d375d782094e2b9dce53ad53a40",
			build = "make",
		},
	},
	keys = {
		{ "<leader>ff", open_find_files, desc = "Find Files" },
		{ "<leader>fg", open_live_grep, desc = "Live Grep" },
		{ "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
		{ "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
		{ "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },
	},
	opts = {
		pickers = {
			live_grep = {
				additional_args = { "--ignore-case", "--hidden" },
			},
			find_files = {
				hidden = true,
			},
		},
		extensions = { fzf = {} },
	},
	config = function(_, opts)
		local telescope = require("telescope")
		local actions = require("telescope.actions")
		opts.defaults = vim.tbl_deep_extend("force", opts.defaults or {}, {
			mappings = {
				i = {
					["<C-j>"] = actions.cycle_history_next,
					["<C-k>"] = actions.cycle_history_prev,
				},
			},
		})
		telescope.setup(opts)
		pcall(telescope.load_extension, "fzf")
	end,
}
