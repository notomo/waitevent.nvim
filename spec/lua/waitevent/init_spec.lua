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

  it("can access triggered autocmd data in callback", function()
    local file_path = helper.test_data:create_file("file")

    local triggered_event
    local editor = waitevent.editor({
      on_done = function(ctx)
        triggered_event = ctx.autocmd.event
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
    vim.cmd.write({ mods = { silent = true } })

    helper.job_wait(job_id)
    assert.equal(0, exit_code)
    assert.equal("BufWritePost", triggered_event)
  end)

  it("opens without waiting by server if events are empty", function()
    local file_path = helper.test_data:create_file("file")

    local called = false
    local editor = waitevent.editor({
      done_events = {},
      on_done = function()
        called = true
      end,
      cancel_events = {},
    })
    local cmd = editor .. " " .. file_path

    local exit_code
    local job_id = helper.job_start(cmd, {
      on_exit = function(_, code)
        exit_code = code
      end,
    })

    helper.wait_autocmd("BufRead", file_path)

    helper.job_wait(job_id)
    assert.equal(0, exit_code)
    assert.is_false(called)
  end)

  it("raises an error if nvim server communication fails", function()
    if vim.fn.has("win32") == 1 then
      pending("skip on windows")
    end

    local file_path = helper.test_data:create_file("file")

    local editor = waitevent.editor({
      open = function(path)
        vim.cmd.split(path)
      end,
    })
    local cmd = editor .. " " .. file_path

    -- hack to raise an error
    require("waitevent.command").open = nil

    local exit_code
    local err = ""
    local job_id = helper.job_start(cmd, {
      on_exit = function(_, code)
        exit_code = code
      end,
      on_stderr = function(_, data)
        err = table.concat(data, "\n")
      end,
    })

    helper.job_wait(job_id)
    assert.no.equal(0, exit_code)
    assert.matches("failed to comunicate with", err)
  end)
end)
