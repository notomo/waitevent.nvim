local vim = vim
local Option = require("waitevent.option")

local M = {}

function M.editor(raw_opts)
  local editor_id = Option.store(raw_opts)
  local opts = Option.from(editor_id)

  local nvim_path = vim.fs.normalize(vim.v.progpath)
  local nvim_address = vim.v.servername
  if vim.fn.filereadable(nvim_address) == 1 then
    nvim_address = vim.fs.normalize(nvim_address)
  end
  local variables = {
    nvim_path = nvim_path,
    nvim_address = nvim_address,
    need_server = opts:need_server(),
    editor_id = editor_id,
  }

  local script = vim.fs.normalize(vim.api.nvim_get_runtime_file("lua/waitevent/script.lua", false)[1])
  return ([[%s -ll %q %q]]):format(nvim_path, script, vim.json.encode(variables))
end

function M.open(file_path, server_address, editor_id)
  file_path = file_path ~= "" and file_path or nil

  local opts = Option.from(editor_id)

  local window_id_before_open = vim.api.nvim_get_current_win()
  opts.open(file_path)

  if not opts:need_server() then
    return ""
  end

  local window_id_after_open = vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_win_get_buf(window_id_after_open)
  local group_name = ("waitevent_%s_%s"):format(bufnr, window_id_after_open)
  local group = vim.api.nvim_create_augroup(group_name, {})

  local new_ctx = function(autocmd)
    return {
      window_id_before_open = window_id_before_open,
      window_id_after_open = window_id_after_open,
      autocmd = autocmd,
    }
  end
  local ch = vim.fn.sockconnect("tcp", server_address)
  local finished = false

  if #opts.done_events > 0 then
    vim.api.nvim_create_autocmd(opts.done_events, {
      group = group,
      buffer = bufnr,
      once = true,
      callback = function(autocmd)
        if finished then
          return
        end
        finished = true

        vim.fn.chansend(ch, "done")
        vim.api.nvim_clear_autocmds({ group = group })

        opts.on_done(new_ctx(autocmd))
      end,
    })
  end

  if #opts.cancel_events > 0 then
    vim.api.nvim_create_autocmd(opts.cancel_events, {
      group = group,
      buffer = bufnr,
      once = true,
      callback = function(autocmd)
        if finished then
          return
        end
        finished = true

        vim.fn.chansend(ch, "cancel")
        vim.api.nvim_clear_autocmds({ group = group })

        opts.on_canceled(new_ctx(autocmd))
      end,
    })
  end

  return ""
end

return M
