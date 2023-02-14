local open_editor = function(address, args)
  local nvim_path = args[1]
  local nvim_address = args[2]
  local editor_id = args[3]
  local file_path = args[4]

  local cmd_args = {
    "--server",
    nvim_address,
    "--remote-expr",
    ([=[luaeval("require([[waitevent.command]]).open(_A[1], _A[2], _A[3])", [%q, %q, %d])]=]):format(
      file_path,
      address,
      editor_id
    ),
  }
  local opts = {
    args = cmd_args,
  }
  -- TODO: stderr handling
  local _, pid_or_err = vim.loop.spawn(nvim_path, opts, function(_, _) end)
  if type(pid_or_err) ~= "number" then
    error(pid_or_err)
  end
end

local wait_message_once = function(server)
  local ok = false

  server:listen(1, function(err)
    assert(not err, err)

    local socket = vim.loop.new_tcp()
    server:accept(socket)

    socket:read_start(function(read_err, message)
      socket:close()
      assert(not read_err, read_err)
      ok = message == "done"
      server:close()
    end)
  end)

  vim.loop.run()

  return ok
end

local main = function(args)
  local server = vim.loop.new_tcp()
  server:bind("127.0.0.1", 0)
  local socket_name = server:getsockname()
  local address = ("%s:%s"):format(socket_name.ip, socket_name.port)

  open_editor(address, args)

  local ok = wait_message_once(server)
  if not ok then
    os.exit(1)
  end
end

main(_G.arg)
