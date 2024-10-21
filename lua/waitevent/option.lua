local vim = vim

local M = {}
M.__index = M

local default = {
  open = function(ctx, ...)
    local paths = { ... }
    for _, path in ipairs(paths) do
      vim.cmd.tabedit(path)
      ctx.tcd()
      vim.bo.bufhidden = "wipe"
    end
    if #paths == 0 then
      vim.cmd.tabedit()
      ctx.tcd()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(ctx.stdin, "\n", { plain = true }))
      vim.bo.modified = false
      vim.bo.bufhidden = "wipe"
    end
    if ctx.row then
      local row = math.min(ctx.row, vim.api.nvim_buf_line_count(0))
      vim.api.nvim_win_set_cursor(0, { row, 0 })
    end
  end,

  done_events = {
    "BufWritePost",
  },
  on_done = function(ctx)
    if vim.api.nvim_win_is_valid(ctx.window_id_after_open) and #vim.api.nvim_list_wins() > 1 then
      vim.api.nvim_win_close(ctx.window_id_after_open, true)
    end
    if not vim.api.nvim_win_is_valid(ctx.window_id_before_open) then
      return
    end
    vim.api.nvim_set_current_win(ctx.window_id_before_open)
  end,

  cancel_events = {
    "BufUnload",
    "BufDelete",
    "BufWipeout",
  },
  on_canceled = function(ctx)
    if not vim.api.nvim_win_is_valid(ctx.window_id_before_open) then
      return
    end
    vim.api.nvim_set_current_win(ctx.window_id_before_open)
  end,
}

local new = function(raw_opts)
  raw_opts = raw_opts or {}
  local opts = vim.tbl_deep_extend("force", default, raw_opts)
  return setmetatable(opts, M)
end

local default_editor_id = 0
local _store = {
  [default_editor_id] = new(),
}
local _editor_id = 1

function M.store(raw_opts)
  if not raw_opts then
    return default_editor_id
  end

  local opts = new(raw_opts)

  local editor_id = _editor_id
  _store[editor_id] = opts
  _editor_id = _editor_id + 1

  return editor_id
end

function M.from(editor_id)
  return _store[editor_id] or new()
end

function M.need_server(self)
  return #self.done_events + #self.cancel_events > 0
end

return M
