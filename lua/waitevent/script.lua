local uv = vim.loop or vim.uv

local open_editor = function(exe_path, server_address, nvim_address, editor_id, file_paths, stdin, row)
  nvim_address = os.getenv("NVIM") or nvim_address

  local variables = {
    file_paths = file_paths,
    row = row,
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
  assert(stderr, "failed to create new stderr pipe")

  local opts = {
    args = cmd_args,
    stdio = { nil, nil, stderr },
  }
  local stderrs = {}
  local _, pid_or_err = uv.spawn(exe_path, opts, function(code)
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
    assert(socket, "failed to create new socket")
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

local run_with_option = function(exe_path, nvim_args)
  local opts = {
    args = nvim_args,
    stdio = { 0, 1, 2 },
  }
  local _, pid_or_err = uv.spawn(exe_path, opts, function(code)
    os.exit(code)
  end)
  if type(pid_or_err) ~= "number" then
    error(pid_or_err)
  end
  uv.run()
end

local BOTTOM_ROW = -1

local extract_inputs = function(nvim_args)
  if nvim_args[1] == "--" then
    return vim.list_slice(nvim_args, 2), ""
  end
  if nvim_args[1] == "-" then
    local stdin = io.stdin:read("*a"):gsub("\n$", "")
    return vim.list_slice(nvim_args, 2), stdin
  end

  local options = {}
  for _, arg in ipairs(nvim_args) do
    if vim.startswith(arg, "-") or vim.startswith(arg, "+") then
      table.insert(options, arg)
    end
  end
  if #options == 0 then
    return nvim_args, ""
  end

  local option = options[1]
  if option == "+" then
    return vim.list_slice(nvim_args, 2), "", BOTTOM_ROW
  end

  local row = option:match("%+(%d+)")
  if row then
    return vim.list_slice(nvim_args, 2), "", tonumber(row)
  end

  return nil
end

local main = function(args)
  local variables = vim.json.decode(args[1])

  local exe_path = uv.exepath()
  assert(exe_path, "failed to get nvim exepath")

  local nvim_args = vim.list_slice(args, 2)
  local file_paths, stdin, row = extract_inputs(nvim_args)
  if not file_paths then
    return run_with_option(exe_path, nvim_args)
  end

  local server = uv.new_tcp()
  assert(server, "failed to create new server")
  server:bind("127.0.0.1", 0)

  local socket_name = server:getsockname()
  assert(socket_name, "failed to getsockname")
  local server_address = ("%s:%s"):format(socket_name.ip, socket_name.port)

  open_editor(exe_path, server_address, variables.nvim_address, variables.editor_id, file_paths, stdin, row)

  local ok = wait_message_once(server, variables.need_server)
  if not ok then
    os.exit(1)
  end
end

main(_G.arg)
