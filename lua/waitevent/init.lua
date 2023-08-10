local M = {}

--- @class WaiteventOpenContext
--- @field working_dir string EDITOR process working directory
--- @field lcd fun(path:string?) function to change window local directory with working_dir. |:lcd|
--- @field tcd fun(path:string?) function to change tab local directory with working_dir. |:tcd|
--- @field stdin string if stdin exists, it is not empty. |--|

--- @class WaiteventEditorOption
--- @field open fun(ctx:WaiteventOpenContext,...:string)? function that be called to open files
--- @field done_events string[]? autocmd events that treated as done
--- @field on_done fun(ctx:WaiteventContext)? function that called on done editor. |WaiteventContext|
--- @field cancel_events string[]? autocmd events that treated as cancel
--- @field on_canceled fun(ctx:WaiteventContext)? function that called on canceled editor. |WaiteventContext|

--- @class WaiteventContext
--- @field window_id_before_open integer: |window-ID| before |WaiteventEditorOption|.open
--- @field window_id_after_open integer: |window-ID| after |WaiteventEditorOption|.open
--- @field autocmd table: |nvim_create_autocmd()| callback argument

--- Returns executable string to use EDITOR environment variable.
--- This executable string uses current opened neovim as editor.
--- if done_events and cancel_events are empty, the EDITOR process finishes as soon as open file.
--- Otherwise, the process waits firing autocmd that be defined done_events or cancel_events.
--- This can use with :terminal or jobstart() or vim.uv.spawn() .
---
--- If you specify option with the executable string, it doesn't execute on current opened neovim.
--- For example, `$EDITOR --version` outputs version as usual.
--- If you want to open file that has hyphen prefixed name, you can use `$EDITOR -- -file` as usual.
--- @param opts WaiteventEditorOption?: |WaiteventEditorOption|
--- @return string # to use EDITOR
function M.editor(opts)
  return require("waitevent.command").editor(opts)
end

return M
