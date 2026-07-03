-- Open the mermaid code block under the cursor in the Mermaid Live Editor.
-- URL fragment uses the editor's plain `base64:` state format (no pako/zlib),
-- so we only need vim.base64 — no external deps.
local M = {}

local BASE_URL = "https://mermaid.live/edit#base64:"
local ns = vim.api.nvim_create_namespace("mermaid-live-hint")

local function is_mermaid_fence(line)
  return line:match("^%s*```%s*mermaid%s*$") ~= nil
end

-- Show an eol hint next to every ```mermaid opening fence.
function M.refresh_hints(bufnr)
  bufnr = bufnr or 0
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i, line in ipairs(lines) do
    if is_mermaid_fence(line) then
      vim.api.nvim_buf_set_extmark(bufnr, ns, i - 1, 0, {
        virt_text = { { "  <leader>m to open", "Comment" } },
        virt_text_pos = "eol",
      })
    end
  end
end

-- Find the mermaid block containing (or nearest above) `row` (1-based).
-- Returns the block's code string, or nil.
function M.block_at(lines, row)
  local fence_start
  for i = row, 1, -1 do
    local l = lines[i]
    if l:match("^%s*```") then
      if l:match("^%s*```%s*mermaid%s*$") then
        fence_start = i
      end
      break -- first fence going up decides: mermaid or not
    end
  end
  if not fence_start then return nil end
  local body = {}
  for i = fence_start + 1, #lines do
    if lines[i]:match("^%s*```%s*$") then
      return table.concat(body, "\n")
    end
    body[#body + 1] = lines[i]
  end
  return nil -- unclosed fence
end

-- Build the Mermaid Live Editor URL for a diagram's source.
function M.encode_url(code)
  local state = vim.json.encode({
    code = code,
    mermaid = vim.json.encode({ theme = "default" }),
    autoSync = true,
    updateDiagram = true,
  })
  return BASE_URL .. vim.base64.encode(state)
end

-- Buffer command: resolve block under cursor, copy URL, open in browser.
function M.open()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local code = M.block_at(lines, row)
  if not code then
    vim.notify("mermaid-live: cursor not inside a ```mermaid block", vim.log.levels.WARN)
    return
  end
  local url = M.encode_url(code)
  vim.fn.setreg("+", url)
  vim.notify("mermaid-live: URL copied to clipboard, opening browser")
  vim.ui.open(url)
end

return M
