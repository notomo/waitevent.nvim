local vim = vim

local M = {}

M.default = {
  open = function(path)
    vim.cmd.tabedit(path)
    vim.bo.bufhidden = "wipe"
  end,

  done_events = {
    "BufWritePost",
  },
  on_done = function(ctx)
    if vim.api.nvim_win_is_valid(ctx.window_id) and #vim.api.nvim_list_wins() > 1 then
      vim.api.nvim_win_close(ctx.window_id, true)
    end
    if not vim.api.nvim_win_is_valid(ctx.original_window_id) then
      return
    end
    vim.api.nvim_set_current_win(ctx.original_window_id)
  end,

  cancel_events = {
    "BufUnload",
    "BufDelete",
    "BufWipeout",
  },
  on_canceled = function(ctx)
    if not vim.api.nvim_win_is_valid(ctx.original_window_id) then
      return
    end
    vim.api.nvim_set_current_win(ctx.original_window_id)
  end,
}

local new = function(raw_opts)
  vim.validate({ raw_opts = { raw_opts, "table", true } })
  raw_opts = raw_opts or {}
  return vim.tbl_deep_extend("force", M.default, raw_opts)
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
  return _store[editor_id] or M.new()
end

function M.count_event(opts)
  return #opts.done_events + #opts.cancel_events
end

return M
