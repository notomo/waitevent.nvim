-- Use for git command editor.
-- This editor finishes the process on save or close.
vim.env.GIT_EDITOR = require("waitevent").editor({
  open = function(path)
    vim.cmd.split(path)
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
