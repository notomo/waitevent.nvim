local vim = vim

local M = {}

function M.editor(raw_opts)
  local editor_id = require("waitevent.option").store(raw_opts)
  local nvim_path = vim.v.progpath
  local nvim_address = vim.v.servername
  local script = vim.api.nvim_get_runtime_file("lua/waitevent/script.lua", false)[1]
  return ([[%s -ll %s %s %s %d]]):format(nvim_path, script, nvim_path, nvim_address, editor_id)
end

function M.open(path, address, editor_id)
  local opts = require("waitevent.option").from(editor_id)

  local original_window_id = vim.api.nvim_get_current_win()
  opts.open(path)
  local window_id = vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_win_get_buf(window_id)

  local ch, err = vim.fn.sockconnect("tcp", address)
  if err then
    error(err)
  end

  local group_name = ("waitevent_%s_%s"):format(bufnr, window_id)
  local group = vim.api.nvim_create_augroup(group_name, {})

  local ctx = {
    original_window_id = original_window_id,
    window_id = window_id,
  }
  local done = false

  if #opts.done_events > 0 then
    vim.api.nvim_create_autocmd(opts.done_events, {
      group = group,
      buffer = bufnr,
      once = true,
      callback = function()
        vim.fn.chansend(ch, "done")
        vim.api.nvim_clear_autocmds({ group = group })

        done = true

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
        if done then
          return
        end

        vim.fn.chansend(ch, "cancel")
        vim.api.nvim_clear_autocmds({ group = group })

        opts.on_canceled(ctx)
      end,
    })
  end

  return ""
end

return M
