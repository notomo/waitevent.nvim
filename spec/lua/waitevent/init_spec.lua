local helper = require("waitevent.test.helper")
local waitevent = helper.require("waitevent")

describe("waitevent.editor()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("returns executable string as EDITOR", function()
    helper.test_data:create_file("file")

    local path = helper.test_data.full_path .. "file"
    local cmd = waitevent.editor() .. " " .. path

    local exit_code
    local job_id = vim.fn.jobstart(cmd, {
      on_exit = function(_, code)
        exit_code = code
      end,
    })

    helper.wait_autocmd("BufRead", path)
    vim.cmd.write({ mods = { silent = true } })

    helper.job_wait(job_id)

    assert.equal(0, exit_code)
  end)

  it("returns executable string that can be canceled with exit_code==1", function()
    helper.test_data:create_file("file")

    local path = helper.test_data.full_path .. "file"
    local cmd = waitevent.editor() .. " " .. path

    local exit_code
    local job_id = vim.fn.jobstart(cmd, {
      on_exit = function(_, code)
        exit_code = code
      end,
    })

    helper.wait_autocmd("BufRead", path)
    vim.cmd.bwipeout()

    helper.job_wait(job_id)

    assert.equal(1, exit_code)
  end)

  it("can custom open", function()
    helper.test_data:create_file("file")

    local file_path = helper.test_data.full_path .. "file"
    local opened = false
    local editor = waitevent.editor({
      open = function(path)
        vim.cmd.split(path)
        opened = true
      end,
    })
    local cmd = editor .. " " .. file_path

    local exit_code
    local job_id = vim.fn.jobstart(cmd, {
      on_exit = function(_, code)
        exit_code = code
      end,
    })

    local ok = vim.wait(1000, function()
      return opened
    end)
    if not ok then
      error("wait timeout")
    end

    assert.tab_count(1)
    assert.window_count(2)
    vim.cmd.write({ mods = { silent = true } })

    helper.job_wait(job_id)
    assert.equal(0, exit_code)
  end)
end)
