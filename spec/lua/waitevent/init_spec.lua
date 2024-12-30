local helper = require("waitevent.test.helper")
local waitevent = helper.require("waitevent")
local assert = require("assertlib").typed(assert)

describe("waitevent.editor()", function()
  before_each(helper.before_each)

  local job_id
  after_each(function()
    pcall(vim.fn.jobstop, job_id)
    job_id = nil
    helper.after_each()
  end)

  it("returns executable string as EDITOR", function()
    local file_path = helper.test_data:create_file("file")
    local editor = waitevent.editor()
    local cmd = editor .. " " .. file_path

    local exit_code
    job_id = helper.job_start(cmd, {
      on_exit = function(_, code)
        exit_code = code
      end,
    })

    helper.wait_autocmd("BufRead", file_path)
    vim.cmd.write({ mods = { silent = true } })

    helper.job_wait(job_id)
    assert.equal(0, exit_code)
  end)

  it("applies current working directory", function()
    local file_path = helper.test_data:create_file("file")
    local editor = waitevent.editor()
    local cmd = editor .. " " .. file_path
    local dir_path = vim.fs.dirname(file_path)

    local exit_code
    job_id = helper.job_start(cmd, {
      on_exit = function(_, code)
        exit_code = code
      end,
      cwd = dir_path,
    })

    helper.wait_autocmd("BufRead", file_path)
    assert.equal(dir_path, vim.fs.normalize(vim.fn.getcwd(0)))
    vim.cmd.write({ mods = { silent = true } })

    helper.job_wait(job_id)
    assert.equal(0, exit_code)
  end)

  it("returns executable string that can be canceled with exit_code==1", function()
    local file_path = helper.test_data:create_file("file")
    local editor = waitevent.editor()
    local cmd = editor .. " " .. file_path

    local exit_code
    job_id = helper.job_start(cmd, {
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
      open = function(ctx, path)
        vim.cmd.split(path)
        ctx.lcd()
      end,
    })
    local cmd = editor .. " " .. file_path

    local exit_code
    job_id = helper.job_start(cmd, {
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

  it("can use without file path", function()
    local cmd = waitevent.editor()

    job_id = helper.job_start(cmd)
    helper.wait_autocmd("TabNew")

    assert.buffer_full_name("")
    assert.tab_count(2)

    vim.cmd.bwipeout()
    helper.job_wait(job_id)
  end)

  it("can use with multiple file paths", function()
    local file_path1 = helper.test_data:create_file("file")
    local file_path2 = helper.test_data:create_file("file")
    local editor = waitevent.editor()
    local cmd = editor .. " " .. file_path1 .. " " .. file_path2

    job_id = helper.job_start(cmd)
    helper.wait_autocmd("TabNew")

    assert.tab_count(3)

    vim.cmd.bwipeout()
    helper.job_wait(job_id)
  end)

  it("can use with relative path", function()
    local file_path = helper.test_data:create_file("file")
    local editor = waitevent.editor()
    local cmd = editor .. " " .. "file"
    local dir_path = vim.fs.dirname(file_path)

    job_id = helper.job_start(cmd, {
      cwd = dir_path,
    })
    helper.wait_autocmd("TabNew")

    assert.buffer_full_name(file_path)

    vim.cmd.bwipeout()
    helper.job_wait(job_id)
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
    job_id = helper.job_start(cmd, {
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
    job_id = helper.job_start(cmd, {
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
      pending("skip on windows", function() end)
    end

    local file_path = helper.test_data:create_file("file")

    local editor = waitevent.editor()
    local cmd = editor .. " " .. file_path

    -- hack to raise an error
    require("waitevent.command").open = nil

    local exit_code
    local err = ""
    job_id = helper.job_start(cmd, {
      on_exit = function(_, code)
        exit_code = code
      end,
      on_stderr = function(_, data)
        err = table.concat(data, "\n")
      end,
    })

    helper.job_wait(job_id)
    assert.no.equal(0, exit_code)
    assert.match("failed to comunicate with", err)
  end)

  it("executes as normal nvim if specified option", function()
    local editor = waitevent.editor()
    local cmd = editor .. " -h"

    local exit_code
    local stdout
    job_id = helper.job_start(cmd, {
      on_exit = function(_, code)
        exit_code = code
      end,
      on_stdout = function(_, data)
        stdout = table.concat(data, "\n")
      end,
      stdout_buffered = true,
    })

    helper.job_wait(job_id)
    assert.equal(0, exit_code)

    assert.match("--help", stdout)
  end)

  it("applies normal nvim exit code", function()
    local editor = waitevent.editor()
    local cmd = editor .. " --invalid-flag"

    local exit_code
    job_id = helper.job_start(cmd, {
      on_exit = function(_, code)
        exit_code = code
      end,
      on_stdout = function() end,
      on_stderr = function() end,
    })

    helper.job_wait(job_id)
    assert.equal(1, exit_code)
  end)

  it("can handle -- and hyphen prefixed file name", function()
    local editor = waitevent.editor()
    local cmd = editor .. " -- -hyphen-prefix-file"

    job_id = helper.job_start(cmd)

    helper.wait_autocmd("BufNew", "*/-hyphen-prefix-file")
    vim.cmd.bwipeout()

    helper.job_wait(job_id)
  end)

  it("can handle - as stdin", function()
    local editor = waitevent.editor()
    local cmd = editor .. " -"

    job_id = helper.job_start(cmd, {}, "stdin_text")

    helper.wait_autocmd("BufNew")
    assert.exists_pattern("stdin_text$")
    vim.cmd.bwipeout()

    helper.job_wait(job_id)
  end)

  it("can handle +{row}", function()
    local file_path = helper.test_data:create_file(
      "file",
      [[
hoge
foo
bar]]
    )

    local editor = waitevent.editor()
    local cmd = editor .. " +2 " .. file_path

    job_id = helper.job_start(cmd)

    helper.wait_autocmd("BufRead", file_path)

    assert.current_line("foo")

    vim.cmd.bwipeout()
    helper.job_wait(job_id)
  end)

  it("can handle +", function()
    local file_path = helper.test_data:create_file(
      "file",
      [[
hoge
foo
bar]]
    )

    local editor = waitevent.editor()
    local cmd = editor .. " + " .. file_path

    job_id = helper.job_start(cmd)

    helper.wait_autocmd("BufRead", file_path)

    assert.current_line("bar")

    vim.cmd.bwipeout()
    helper.job_wait(job_id)
  end)
end)
