-- Local LLM autocomplete (ghost text) backed by a self-hosted Ollama running
-- Qwen2.5-Coder. Server lives in the `local-autocomplete` repo (docker).
--
-- Virtualtext mode: completions appear inline as you type, accepted with the
-- <A-*> keymaps below — self-contained, does NOT touch blink.cmp's config.
-- Set $MINUET_MODEL to match whatever the container serves (default 3b).
return {
	"milanglacier/minuet-ai.nvim",
	version = "v0.9.0",
	dependencies = { "nvim-lua/plenary.nvim" },
	event = "InsertEnter",
	opts = {
		-- Talk to Ollama's OpenAI-compatible FIM endpoint (prompt + suffix).
		provider = "openai_fim_compatible",
		n_completions = 1, -- one suggestion; cheaper + lower latency.
		-- context_window is in CHARACTERS (~4 chars/token), NOT tokens. 8000 ≈ 2k
		-- tokens of surrounding code — the model handles 32k, so there's headroom.
		-- The <A-C> keymap below sends a much bigger window for one request.
		context_window = 8000,
		-- Local model + bigger context => 3s (minuet's default) times out and you
		-- get nothing. Streaming is off for FIM, so the timeout must cover the whole
		-- response. 10s is comfortable on GPU; raise it if you run on CPU.
		request_timeout = 10,
		provider_options = {
			openai_fim_compatible = {
				-- Ollama ignores auth; minuet just needs a non-empty env var name.
				api_key = "TERM",
				name = "Ollama",
				end_point = "http://localhost:11434/v1/completions",
				model = vim.env.MINUET_MODEL or "qwen2.5-coder:3b",
				optional = {
					max_tokens = 32,
					top_p = 0.9,
				},
			},
		},
		virtualtext = {
			auto_trigger_ft = { "*" },
			keymap = {
				accept = "<A-A>", -- accept whole suggestion
				accept_line = "<A-a>", -- accept one line
				accept_n_lines = "<A-z>", -- accept N lines (prompts for count)
				prev = "<A-[>",
				next = "<A-]>",
				dismiss = "<A-e>",
			},
		},
	},
	config = function(_, opts)
		require("minuet").setup(opts)

		-- minuet arms auto-trigger via a FileType autocmd created in setup(), but it
		-- loads lazily on InsertEnter — AFTER FileType already fired for the buffer
		-- you're in. So the FIRST buffer never auto-triggers (no ghost text). Arm
		-- the current buffer manually; later buffers are handled by minuet's autocmd.
		do
			local vt = require("minuet").config.virtualtext
			local ft = vim.bo.filetype
			local ft_ok = vim.tbl_contains(vt.auto_trigger_ft, "*") or vim.tbl_contains(vt.auto_trigger_ft, ft)
			if ft_ok and not vim.tbl_contains(vt.auto_trigger_ignore_ft or {}, ft) then
				vim.b.minuet_virtual_text_auto_trigger = true
			end
		end

		-- One-shot "send more context" trigger. Normal completions use the 8000-char
		-- window above; press <A-C> to fire a single completion with a much larger
		-- window (for when the local context isn't enough). trigger() builds the
		-- prompt synchronously, so restoring on the next tick is safe.
		vim.keymap.set("i", "<A-C>", function()
			local minuet = require("minuet")
			local vt = require("minuet.virtualtext")
			local saved = minuet.config.context_window
			minuet.config.context_window = 16000
			vt.action.dismiss()
			vt.action.next() -- fresh request, no suggestion shown => triggers
			vim.schedule(function()
				minuet.config.context_window = saved
			end)
		end, { desc = "minuet: complete with extra context" })

		-- Warn if the local Ollama server (the docker container) isn't reachable,
		-- otherwise autocomplete just silently does nothing. Async curl against the
		-- same host as the endpoint above. `:MinuetHealth` re-runs it on demand;
		-- it also runs once now (config fires on the first InsertEnter).
		local host = opts.provider_options.openai_fim_compatible.end_point:match("^(https?://[^/]+)")
		local function health_check()
			vim.system({ "curl", "-sf", "-m", "2", host .. "/api/tags" }, {}, function(res)
				vim.schedule(function()
					if res.code ~= 0 then
						vim.notify(
							"minuet: autocomplete server unreachable at "
								.. host
								.. " — start it with local-autocomplete/start.sh",
							vim.log.levels.WARN
						)
					end
				end)
			end)
		end
		vim.api.nvim_create_user_command(
			"MinuetHealth",
			health_check,
			{ desc = "minuet: ping the autocomplete server" }
		)
		health_check()

		-- When a completion fails, don't spam errors if the local-autocomplete
		-- service simply isn't running: prompt to start it once, then stay quiet
		-- (re-checking the service at most every 30s). If the service IS up but
		-- requests still fail, errors pass through as normal. Gate minuet's own
		-- warn/error notifications via the injectable core in methods/.
		local utils = require("minuet.utils")
		local orig_notify = utils.notify
		local function check_service(cb)
			vim.system({ "systemctl", "is-active", "--quiet", "local-autocomplete" }, {}, function(res)
				vim.schedule(function()
					cb(res.code == 0)
				end)
			end)
		end
		local function prompt_start()
			vim.notify(
				"minuet: local-autocomplete service is not running — start it with "
					.. "`sudo systemctl start local-autocomplete` (errors silenced until it's up)",
				vim.log.levels.WARN
			)
		end
		local gate = require("methods.minuet_error_gate").new(check_service, prompt_start)
		utils.notify = function(msg, minuet_level, vim_level, opts2)
			if minuet_level ~= "warn" and minuet_level ~= "error" then
				return orig_notify(msg, minuet_level, vim_level, opts2)
			end
			gate(function()
				orig_notify(msg, minuet_level, vim_level, opts2)
			end)
		end
	end,
}
