# waitevent.nvim

This plugin provides the way to avoid nested nvim.

## Requirements

- Neovim nightly. This plugin uses `nvim -ll {script}`.

## Example

```lua
-- Use for git command editor.
-- This editor finishes the process on save or close.
vim.env.GIT_EDITOR = require("waitevent").editor({
  open = function(ctx, path)
    vim.cmd.split(path)
    ctx.lcd()
    vim.bo.bufhidden = "wipe"
  end,
})

-- Use for `nvim {file_path}` in :terminal.
-- This editor finishes the process as soon as open.
-- The fowllowing shell settings is convinient (optional).
-- `export EDITOR=nvim` in .bash_profile
-- `alias nvim="${EDITOR}"` in .bashrc
vim.env.EDITOR = require("waitevent").editor({
  done_events = {},
  cancel_events = {},
})

-- all default options
local default = {
  open = function(ctx, path)
    vim.cmd.tabedit(path)
    ctx.lcd()
    vim.bo.bufhidden = "wipe"
  end,

  done_events = {
    "BufWritePost",
  },
  on_done = function(ctx)
    if vim.api.nvim_win_is_valid(ctx.window_id_after_open) and #vim.api.nvim_list_wins() > 1 then
      vim.api.nvim_win_close(ctx.window_id_after_open, true)
    end
    if not vim.api.nvim_win_is_valid(ctx.window_id_before_open) then
      return
    end
    vim.api.nvim_set_current_win(ctx.window_id_before_open)
  end,

  cancel_events = {
    "BufUnload",
    "BufDelete",
    "BufWipeout",
  },
  on_canceled = function(ctx)
    if not vim.api.nvim_win_is_valid(ctx.window_id_before_open) then
      return
    end
    vim.api.nvim_set_current_win(ctx.window_id_before_open)
  end,
}
require("waitevent").editor(default)
```