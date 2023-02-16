local helper = require("vusted.helper")
local plugin_name = helper.get_module_root(...)

helper.root = helper.find_plugin_root(plugin_name)

function helper.before_each()
  helper.test_data = require("waitevent.vendor.misclib.test.data_dir").setup(helper.root)
end

function helper.after_each()
  helper.test_data:teardown()
  helper.cleanup()
  helper.cleanup_loaded_modules(plugin_name)
end

function helper.job_wait(job_id)
  local ok = vim.wait(1000, function()
    local running = vim.fn.jobwait({ job_id }, 0)[1] == -1
    return not running
  end)
  if not ok then
    error("job_wait timeout")
  end
end

function helper.wait_autocmd(events, pattern)
  vim.validate({
    events = { events, "string", "table" },
    pattern = { pattern, "string" },
  })

  local called = false
  local group = vim.api.nvim_create_augroup("waitevent_test", {})
  vim.api.nvim_create_autocmd(events, {
    group = group,
    pattern = pattern,
    callback = function()
      called = true
    end,
  })

  local ok = vim.wait(1000, function()
    return called
  end)
  if not ok then
    error("wait_autocmd timeout")
  end
end

function helper.job_start(cmd, raw_opts)
  local default = {
    on_stdout = function(_, data)
      print(table.concat(data, "\n"))
    end,
    on_stderr = function(_, data)
      print(table.concat(data, "\n"))
    end,
    stderr_buffered = true,
    stdout_buffered = true,
  }
  local opts = vim.tbl_deep_extend("force", default, raw_opts or {})
  if vim.fn.has("win32") == 1 then
    local shell_cmd = ([[cmd.exe /c %s]]):format(vim.fn.shellescape(cmd))
    return vim.fn.jobstart(shell_cmd, opts)
  end
  return vim.fn.jobstart(cmd, opts)
end

local asserts = require("vusted.assert").asserts
local asserters = require(plugin_name .. ".vendor.assertlib").list()
require(plugin_name .. ".vendor.misclib.test.assert").register(asserts.create, asserters)

return helper
