local M = {}

--- Returns executable string to use EDITOR environment variable.
--- @param opts table|nil: TODO
--- @return string: to use EDITOR
function M.editor(opts)
  return require("waitevent.command").editor(opts)
end

return M
