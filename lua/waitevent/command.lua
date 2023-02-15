local vim = vim
local Option = require("waitevent.option")

local M = {}

function M.editor(raw_opts)
  local editor_id = Option.store(raw_opts)
  local opts = Option.from(editor_id)

  local nvim_path = vim.v.progpath
  local variables = {
    nvim_path = nvim_path,
    nvim_address = vim.v.servername,
    need_server = opts:need_server(),
    editor_id = editor_id,
  }

  local script = vim.api.nvim_get_runtime_file("lua/waitevent/script.lua", false)[1]
  return ([[%s -ll %q %q]]):format(nvim_path, script, vim.json.encode(variables))
end

function M.open(path, server_address, editor_id)
  local opts = Option.from(editor_id)

  local original_window_id = vim.api.nvim_get_current_win()
  opts.open(path)

  if not opts:need_server() then
    return ""
  end

  local window_id = vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_win_get_buf(window_id)
  local group_name = ("waitevent_%s_%s"):format(bufnr, window_id)
  local group = vim.api.nvim_create_augroup(group_name, {})

  local ctx = {
    original_window_id = original_window_id,
    window_id = window_id,
  }
  local ch = vim.fn.sockconnect("tcp", server_address)
  local finished = false

  if #opts.done_events > 0 then
    vim.api.nvim_create_autocmd(opts.done_events, {
      group = group,
      buffer = bufnr,
      once = true,
      callback = function()
        if finished then
          return
        end
        finished = true

        vim.fn.chansend(ch, "done")
        vim.api.nvim_clear_autocmds({ group = group })

        opts.on_done(ctx)
      end,
    })
  end

  if #opts.cancel_events > 0 then
    vim.api.nvim_create_autocmd(opts.cancel_events, {
      group = group,
      buffer = bufnr,
      once = true,
      callback = function()
        if finished then
          return
        end
        finished = true

        vim.fn.chansend(ch, "cancel")
        vim.api.nvim_clear_autocmds({ group = group })

        opts.on_canceled(ctx)
      end,
    })
  end

  return ""
end

return M
