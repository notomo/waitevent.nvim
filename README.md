# waitevent.nvim

WIP

## Example

```lua
vim.env.GIT_EDITOR = require("waitevent").editor({
  open = function(path)
    vim.cmd.split(path)
    vim.bo.bufhidden = "wipe"
  end,
})
```