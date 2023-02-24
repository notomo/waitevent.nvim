local M = {}

--- @class WaiteventEditorOption
--- @field open fun(path:string?) function that be called to open file
--- @field done_events string[] autocmd events that treated as done
--- @field on_done fun(ctx:WaiteventContext) function that called on done editor. |WaiteventContext|
--- @field cancel_events string[] autocmd events that treated as cancel
--- @field on_canceled fun(ctx:WaiteventContext) function that called on canceled editor. |WaiteventContext|

--- @class WaiteventContext
--- @field window_id_before_open integer: |window-ID| before |WaiteventEditorOption|.open
--- @field window_id_after_open integer: |window-ID| after |WaiteventEditorOption|.open
--- @field autocmd table: |nvim_create_autocmd()| callback argument

--- Returns executable string to use EDITOR environment variable.
--- This executable string uses current opened neovim as editor.
--- if done_events and cancel_events are empty, the EDITOR process finishes as soon as open file.
--- Otherwise, the process waits firing autocmd that be defined done_events or cancel_events.
--- This can use with :terminal or jobstart() or vim.loop.spawn() .
--- @param opts WaiteventEditorOption?: |WaiteventEditorOption|
--- @return string: to use EDITOR
function M.editor(opts)
  return require("waitevent.command").editor(opts)
end

return M
