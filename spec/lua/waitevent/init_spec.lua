local helper = require("waitevent.test.helper")
local waitevent = helper.require("waitevent")

describe("waitevent.editor()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("returns executable string as EDITOR", function()
    local file_path = helper.test_data:create_file("file")
    local editor = waitevent.editor()
    local cmd = editor .. " " .. file_path

    local exit_code
    local job_id = helper.job_start(cmd, {
      on_exit = function(_, code)
        exit_code = code
      end,
    })

    helper.wait_autocmd("BufRead", file_path)
    vim.cmd.write({ mods = { silent = true } })

    helper.job_wait(job_id)
    assert.equal(0, exit_code)
  end)

  it("returns executable string that can be canceled with exit_code==1", function()
    local file_path = helper.test_data:create_file("file")
    local editor = waitevent.editor()
    local cmd = editor .. " " .. file_path

    local exit_code
    local job_id = helper.job_start(cmd, {
      on_exit = function(_, code)
        exit_code = code
      end,
    })

    helper.wait_autocmd("BufRead", file_path)
    vim.cmd.bwipeout()

    helper.job_wait(job_id)
    assert.equal(1, exit_code)
  end)

  it("can custom open", function()
    local file_path = helper.test_data:create_file("file")

    local editor = waitevent.editor({
      open = function(path)
        vim.cmd.split(path)
      end,
    })
    local cmd = editor .. " " .. file_path

    local exit_code
    local job_id = helper.job_start(cmd, {
      on_exit = function(_, code)
        exit_code = code
      end,
    })

    helper.wait_autocmd("BufRead", file_path)
    assert.tab_count(1)
    assert.window_count(2)
    vim.cmd.write({ mods = { silent = true } })

    helper.job_wait(job_id)
    assert.equal(0, exit_code)
  end)
end)
