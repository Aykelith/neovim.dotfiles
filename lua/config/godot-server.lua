-- Godot external editor support.
-- When nvim opens inside a Godot project, start a server on {project}/server.pipe
-- so Godot's "Exec Flags" can --remote-send files/cursor to this instance.
-- Godot side: Editor Settings > Text Editor > External:
--   Exec Path:  path to nvim
--   Exec Flags: --server {project}/server.pipe --remote-send "<C-\><C-N>:e {file}<CR>:call cursor({line}+1,{col})<CR>"

-- Walk up from cwd looking for project.godot. ponytail: 4 levels is plenty for
-- editing a script nested a few dirs deep; bump if you open deeper.
local dir = vim.fn.getcwd()
for _ = 1, 4 do
  if vim.uv.fs_stat(dir .. '/project.godot') then
    local pipe = dir .. '/server.pipe'
    if not vim.uv.fs_stat(pipe) then
      vim.fn.serverstart(pipe)
    end
    -- Set a distinct terminal title so the Godot wrapper can raise this exact
    -- window (needs Alacritty's dynamic_title enabled, which is the default).
    vim.o.title = true
    vim.o.titlestring = 'godot-nvim │ %t'
    -- If inside tmux, record this pane so the Godot wrapper can switch to it.
    local pane = vim.env.TMUX and vim.env.TMUX_PANE
    if pane then
      vim.fn.writefile({ pane }, pipe .. '.tmux')
      vim.api.nvim_create_autocmd('VimLeavePre', {
        callback = function() os.remove(pipe .. '.tmux') end,
      })
    end
    break
  end
  dir = vim.fn.fnamemodify(dir, ':h')
end
