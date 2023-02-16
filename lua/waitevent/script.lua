local open_editor = function(server_address, nvim_path, editor_id, file_path)
  local nvim_address = os.getenv("NVIM")
  local cmd_args = {
    "--server",
    nvim_address,
    "--remote-expr",
    ([=[luaeval("require([[waitevent.command]]).open(_A[1], _A[2], _A[3])", [%q, %q, %d])]=]):format(
      file_path,
      server_address,
      editor_id
    ),
  }

  local stderr = vim.loop.new_pipe()

  local opts = {
    args = cmd_args,
    stdio = { nil, nil, stderr },
  }
  local stderrs = {}
  local _, pid_or_err = vim.loop.spawn(nvim_path, opts, function(code)
    if code == 0 or #stderrs == 0 then
      stderr:close()
      return
    end
    error(("failed to comunicate with %s: %s"):format(nvim_address, table.concat(stderrs, "\n")))
  end)
  if type(pid_or_err) ~= "number" then
    error(pid_or_err)
  end

  vim.loop.read_start(stderr, function(err, data)
    assert(not err, err)
    if data then
      table.insert(stderrs, data)
    end
  end)
end

local wait_message_once = function(server, need_server)
  if not need_server then
    server:close()
    vim.loop.run()
    return true
  end

  local ok = false

  server:listen(1, function(err)
    assert(not err, err)

    local socket = vim.loop.new_tcp()
    server:accept(socket)

    socket:read_start(function(read_err, message)
      assert(not read_err, read_err)
      ok = message == "done"
      socket:close()
      server:close()
    end)
  end)

  vim.loop.run()

  return ok
end

local main = function(args)
  local variables = vim.json.decode(args[1])
  local file_path = args[2]

  local server = vim.loop.new_tcp()
  server:bind("127.0.0.1", 0)
  local socket_name = server:getsockname()
  local server_address = ("%s:%s"):format(socket_name.ip, socket_name.port)

  open_editor(server_address, variables.nvim_path, variables.editor_id, file_path)

  local ok = wait_message_once(server, variables.need_server)
  if not ok then
    os.exit(1)
  end
end

main(_G.arg)
