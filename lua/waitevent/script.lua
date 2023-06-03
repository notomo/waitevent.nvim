local uv = vim.loop or vim.uv

local open_editor = function(server_address, nvim_address, editor_id, file_paths, stdin)
  nvim_address = os.getenv("NVIM") or nvim_address

  local variables = {
    file_paths = file_paths,
    server_address = server_address,
    editor_id = editor_id,
    working_dir = uv.cwd(),
    stdin = stdin,
  }
  local cmd_args = {
    "--server",
    nvim_address,
    "-u",
    "NONE",
    "-i",
    "NONE",
    "--remote-expr",
    ([=[luaeval("require([[waitevent.command]]).open(_A[1])", [%q])]=]):format(vim.json.encode(variables)),
  }

  local stderr = uv.new_pipe()

  local opts = {
    args = cmd_args,
    stdio = { nil, nil, stderr },
  }
  local stderrs = {}
  local _, pid_or_err = uv.spawn(uv.exepath(), opts, function(code)
    if code == 0 or #stderrs == 0 then
      stderr:close()
      return
    end
    error(("failed to comunicate with %s: %s"):format(nvim_address, table.concat(stderrs, "\n")))
  end)
  if type(pid_or_err) ~= "number" then
    error(pid_or_err)
  end

  uv.read_start(stderr, function(err, data)
    assert(not err, err)
    if data then
      table.insert(stderrs, data)
    end
  end)
end

local wait_message_once = function(server, need_server)
  if not need_server then
    server:close()
    uv.run()
    return true
  end

  local ok = false

  server:listen(1, function(err)
    assert(not err, err)

    local socket = uv.new_tcp()
    server:accept(socket)

    socket:read_start(function(read_err, message)
      assert(not read_err, read_err)
      ok = message == "done"
      socket:close()
      server:close()
    end)
  end)

  uv.run()

  return ok
end

local run_with_option = function(nvim_args)
  local opts = {
    args = nvim_args,
    stdio = { 0, 1, 2 },
  }
  local _, pid_or_err = uv.spawn(uv.exepath(), opts, function(code)
    os.exit(code)
  end)
  if type(pid_or_err) ~= "number" then
    error(pid_or_err)
  end
  uv.run()
end

local extract_inputs = function(nvim_args)
  if nvim_args[1] == "--" then
    return vim.list_slice(nvim_args, 2), ""
  end
  if nvim_args[1] == "-" then
    return vim.list_slice(nvim_args, 2), io.stdin:read("*a"):gsub("\n$", "")
  end

  for _, arg in ipairs(nvim_args) do
    if vim.startswith(arg, "-") or vim.startswith(arg, "+") then
      return nil
    end
  end

  return nvim_args, ""
end

local main = function(args)
  local variables = vim.json.decode(args[1])

  local nvim_args = vim.list_slice(args, 2)
  local file_paths, stdin = extract_inputs(nvim_args)
  if not file_paths then
    return run_with_option(nvim_args)
  end

  local server = uv.new_tcp()
  server:bind("127.0.0.1", 0)
  local socket_name = server:getsockname()
  local server_address = ("%s:%s"):format(socket_name.ip, socket_name.port)

  open_editor(server_address, variables.nvim_address, variables.editor_id, file_paths, stdin)

  local ok = wait_message_once(server, variables.need_server)
  if not ok then
    os.exit(1)
  end
end

main(_G.arg)
