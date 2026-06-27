-- Gate minuet error notifications behind the `local-autocomplete` service state.
--
-- When minuet can't get an answer from Ollama, the first failure checks whether
-- the systemd service is even running. If it's DOWN, prompt the user to start it
-- ONCE, then swallow further errors (re-checking the service at most every 30s).
-- If the service is UP but requests still fail, errors pass through as normal.
--
-- The core is dependency-injected (check/prompt/now) so it's unit-testable
-- without systemd. See tests/e2e_spec.lua.
local M = {}

local DEFAULT_INTERVAL_MS = 30 * 1000

-- check(cb): async service probe; calls cb(true) if up, cb(false) if down.
-- prompt(): show the "please start the service" message (once per outage).
-- opts.interval_ms: min gap between service probes (default 30s).
-- opts.now(): monotonic ms (default vim.uv.now); injectable for tests.
--
-- Returns gate(emit): emit() is the real minuet notification. Called when the
-- service is up; suppressed (after one prompt) while it's down.
function M.new(check, prompt, opts)
  opts = opts or {}
  local interval = opts.interval_ms or DEFAULT_INTERVAL_MS
  local now = opts.now or function() return vim.uv.now() end

  local state = { last_check = nil, up = nil, prompted = false }

  return function(emit)
    local function decide(up)
      if up then
        state.prompted = false -- healthy again: re-arm the prompt for next outage
        emit()
      elseif not state.prompted then
        state.prompted = true
        prompt()
      end
      -- down + already prompted: swallow.
    end

    local t = now()
    if state.up ~= nil and state.last_check and (t - state.last_check) < interval then
      decide(state.up)
      return
    end
    state.last_check = t
    check(function(up)
      state.up = up
      decide(up)
    end)
  end
end

return M
