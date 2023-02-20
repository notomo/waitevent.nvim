local util = require("genvdoc.util")
local plugin_name = vim.env.PLUGIN_NAME
local full_plugin_name = plugin_name .. ".nvim"

local example_path = ("./spec/lua/%s/example.lua"):format(plugin_name)
vim.api.nvim_exec("luafile " .. example_path, true)

local get_default_option_as_text = function()
  local path = [[./lua/waitevent/option.lua]]

  local f = io.open(path, "r")
  local str = f:read("*a")
  f:close()

  local query = vim.treesitter.query.parse_query(
    "lua",
    [[
(variable_declaration
  (assignment_statement
    (variable_list
        name: (_) @name (#match? @name "^default$")
    )
  )
) @target
]]
  )

  local parser = vim.treesitter.get_string_parser(str, "lua")
  local trees = parser:parse()
  local root = trees[1]:root()
  local _, match = query:iter_matches(root, str, 0, -1)()

  local target_node
  for id, node in pairs(match) do
    local captured = query.captures[id]
    if captured == "target" then
      target_node = node
      break
    end
  end

  return vim.treesitter.query.get_node_text(target_node, str)
end

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
        return util.help_code_block_from_file(example_path)
      end,
    },
  },
})

local gen_readme = function()
  local f = io.open(example_path, "r")
  local exmaple = f:read("*a")
  f:close()

  local content = ([[
# %s

This plugin provides the way to avoid nested nvim.

## Requirements

- Neovim nightly. This plugin uses `nvim -ll {script}`.

## Example

```lua
%s
-- all default options
%s
require("waitevent").editor(default)
```]]):format(full_plugin_name, exmaple, get_default_option_as_text())

  local readme = io.open("README.md", "w")
  readme:write(content)
  readme:close()
end
gen_readme()
