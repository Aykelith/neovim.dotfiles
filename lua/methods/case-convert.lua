-- Convert the visual selection between naming cases.
local M = {}

-- Split an identifier into lowercase words: separators are dropped, camel humps
-- and acronym boundaries ("HTTPServer" -> http, server) become splits.
local function split(text)
  local out = {}
  for chunk in text:gmatch("[%a%d]+") do
    chunk = chunk:gsub("(%l)(%u)", "%1 %2"):gsub("(%d)(%u)", "%1 %2"):gsub("(%u)(%u%l)", "%1 %2")
    for word in chunk:gmatch("%S+") do
      out[#out + 1] = word:lower()
    end
  end
  return out
end

M.styles = {
  snake = function(words)
    return table.concat(words, "_")
  end,
  upper_snake = function(words)
    return table.concat(words, "_"):upper()
  end,
  kebab = function(words)
    return table.concat(words, "-")
  end,
  camel = function(words)
    local out = {}
    for i, word in ipairs(words) do
      out[i] = word:sub(1, 1):upper() .. word:sub(2)
    end
    return table.concat(out)
  end,
}

function M.convert(style)
  -- The '< '> marks only hold this selection once visual mode is left; "x"
  -- makes the <Esc> run before we read them.
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)

  local sr, sc = unpack(vim.api.nvim_buf_get_mark(0, "<"))
  local er, ec = unpack(vim.api.nvim_buf_get_mark(0, ">"))
  local last = vim.api.nvim_buf_get_lines(0, er - 1, er, true)[1]
  -- '> is inclusive, and unbounded on a linewise selection. ponytail: a byte
  -- bump is enough to make it exclusive -- identifiers are ASCII.
  ec = math.min(ec + 1, #last)

  local text = table.concat(vim.api.nvim_buf_get_text(0, sr - 1, sc, er - 1, ec, {}), "\n")
  local words = split(text)
  if #words == 0 then
    return
  end

  vim.api.nvim_buf_set_text(0, sr - 1, sc, er - 1, ec, { M.styles[style](words) })
end

return M
