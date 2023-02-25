local util = require("genvdoc.util")
local plugin_name = vim.env.PLUGIN_NAME
local full_plugin_name = plugin_name .. ".nvim"

local example_path = ("./spec/lua/%s/example.lua"):format(plugin_name)
local example = util.read_all(example_path)
local default_opttion_as_text = util.extract_variable_as_text("./lua/waitevent/option.lua", "default")
example = example
  .. ([[

-- all default options
%s
require("waitevent").editor(default)]]):format(default_opttion_as_text)
util.execute(example)

require("genvdoc").generate(full_plugin_name, {
  source = { patterns = { ("lua/%s/init.lua"):format(plugin_name) } },
  chapters = {
    {
      name = function(group)
        return "Lua module: " .. group
      end,
      group = function(node)
        if node.declaration == nil or node.declaration.type ~= "function" then
          return nil
        end
        return node.declaration.module
      end,
    },
    {
      name = "STRUCTURE",
      group = function(node)
        if node.declaration == nil or node.declaration.type ~= "class" then
          return nil
        end
        return "STRUCTURE"
      end,
    },
    {
      name = "EXAMPLES",
      body = function()
        return util.help_code_block(example)
      end,
    },
  },
})

local gen_readme = function()
  local content = ([[
# %s

This plugin provides the way to avoid nested nvim.

## Requirements

- Neovim nightly. This plugin uses `nvim -ll {script}`.

## Example

```lua
%s
```]]):format(full_plugin_name, example)

  local readme = io.open("README.md", "w")
  readme:write(content)
  readme:close()
end
gen_readme()
