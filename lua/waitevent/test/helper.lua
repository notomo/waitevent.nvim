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

local asserts = require("vusted.assert").asserts
local asserters = require(plugin_name .. ".vendor.assertlib").list()
require(plugin_name .. ".vendor.misclib.test.assert").register(asserts.create, asserters)

return helper
