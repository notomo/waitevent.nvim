local vim = vim
local Option = require("waitevent.option")

local M = {}

function M.editor(raw_opts)
  local editor_id = Option.store(raw_opts)
  local opts = Option.from(editor_id)

  local nvim_address = vim.v.servername
  if vim.fn.filereadable(nvim_address) == 1 then
    nvim_address = vim.fs.normalize(nvim_address)
  end
  local variables = {
    nvim_address = nvim_address,
    need_server = opts:need_server(),
    editor_id = editor_id,
  }

  local nvim_path = vim.fs.normalize(vim.v.progpath)
  local script = vim.fs.normalize(vim.api.nvim_get_runtime_file("lua/waitevent/script.lua", false)[1])
  return ([[%s -ll %q %q]]):format(nvim_path, script, vim.json.encode(variables))
end

local is_relative_path = function(file_path)
  if vim.startswith(file_path, "/") then
    return false
  end
  if file_path:match("^[a-zA-Z][a-zA-Z0-9+-.]*:/") then
    return false
  end
  return true
end

local to_absolute_path = function(working_dir, file_path)
  file_path = vim.fs.normalize(file_path)
  if is_relative_path(file_path) then
    return vim.fn.simplify(vim.fs.joinpath(working_dir, file_path))
  end
  return file_path
end

function M.open(decoded_variables)
  local variables = vim.json.decode(decoded_variables)

  local opts = Option.from(variables.editor_id)

  local working_dir = vim.fs.normalize(variables.working_dir)
  local open_ctx = {
    working_dir = working_dir,
    lcd = function(path)
      local dir_path = path or working_dir
      local escaped = ([[`='%s'`]]):format(dir_path:gsub("'", "''"))
      vim.cmd.lcd({ args = { escaped }, mods = { silent = true } })
    end,
    tcd = function(path)
      local dir_path = path or working_dir
      local escaped = ([[`='%s'`]]):format(dir_path:gsub("'", "''"))
      vim.cmd.tcd({ args = { escaped }, mods = { silent = true } })
    end,
    stdin = variables.stdin,
  }

  local file_paths = vim.tbl_map(function(file_path)
    return to_absolute_path(working_dir, file_path)
  end, variables.file_paths)

  local window_id_before_open = vim.api.nvim_get_current_win()
  opts.open(open_ctx, unpack(file_paths))

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
  local ch = vim.fn.sockconnect("tcp", variables.server_address)
  local finished = false

  if #opts.done_events > 0 then
    vim.api.nvim_create_autocmd(opts.done_events, {
      group = group,
      pattern = file_paths,
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
      pattern = file_paths,
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
