local M = {}

--- @class waitevent_editor_option
--- @field open fun(path:string) function that be called to open file
--- @field done_events string[] autocmd events that treated as done
--- @field on_done fun(ctx:waitevent_context) function that called on done editor. |waitevent_context|
--- @field cancel_events string[] autocmd events that treated as cancel
--- @field on_canceled fun(ctx:waitevent_context) function that called on canceled editor. |waitevent_context|

--- @class waitevent_context
--- @field window_id_before_open integer: |window-ID| before |waitevent_editor_option|.open
--- @field window_id_after_open integer: |window-ID| after |waitevent_editor_option|.open
--- @field autocmd table: |nvim_create_autocmd()| callback argument

--- Returns executable string to use EDITOR environment variable.
--- @param opts waitevent_editor_option?: |waitevent_editor_option|
--- @return string: to use EDITOR
function M.editor(opts)
  return require("waitevent.command").editor(opts)
end

return M
