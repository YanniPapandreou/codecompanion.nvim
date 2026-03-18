local completion = require("codecompanion.providers.completion")
local config = require("codecompanion.config")
local triggers = require("codecompanion.triggers")

local api = vim.api

local M = {}

---Completefunc for mini.completion buffers.
---
---Unlike the default omnifunc, tool and editor_context words omit braces so
---Vim's native prefix-matching filter works correctly (e.g. typing "insert"
---after "@" matches "insert_edit_into_file"). The braces are restored by a
---CompleteDone autocmd in setup.lua.
---@param findstart number 1 for finding start position, 0 for returning completions
---@param base string The text to complete (only used when findstart == 0)
---@return number|table
function M.completefunc(findstart, base)
  if findstart == 1 then
    local line = api.nvim_get_current_line()
    local col = api.nvim_win_get_cursor(0)[2]
    local before_cursor = line:sub(1, col)

    local patterns = {
      triggers.mappings.editor_context .. "[%w_]*$",
      triggers.mappings.slash_commands .. "[%w_]*$",
      triggers.mappings.tools .. "[%w_]*$",
    }

    if config.interactions.chat.slash_commands.opts.acp.enabled then
      local escaped = vim.pesc(triggers.mappings.acp_slash_commands)
      table.insert(patterns, escaped .. "[%w_]*$")
    end

    for _, pattern in ipairs(patterns) do
      local start_pos = before_cursor:find(pattern)
      if start_pos then
        return start_pos - 1
      end
    end

    return -1
  else
    local trigger_char = base:sub(1, 1)
    local typed = base:sub(2):lower()
    local items = {}

    if trigger_char == triggers.mappings.acp_slash_commands then
      local acp_cmds = completion.acp_commands(api.nvim_get_current_buf())
      for _, item in ipairs(acp_cmds) do
        local name = item.label:sub(2)
        if vim.startswith(name:lower(), typed) then
          table.insert(items, {
            word = item.label,
            abbr = name,
            menu = item.detail or item.description,
            kind = "f",
            icase = 1,
            user_data = {
              type = item.type,
              command = item.command,
            },
          })
        end
      end

    elseif trigger_char == triggers.mappings.editor_context then
      local vars = completion.editor_context()
      for _, item in ipairs(vars) do
        local name = item.label:sub(2)
        if vim.startswith(name:lower(), typed) then
          table.insert(items, {
            -- word without braces so Vim's prefix filter works while typing
            word = triggers.mappings.editor_context .. name,
            abbr = name,
            menu = item.detail or item.description,
            kind = "v",
            icase = 1,
            user_data = { needs_braces = true },
          })
        end
      end

    elseif trigger_char == triggers.mappings.tools then
      local tools = completion.tools()
      for _, item in ipairs(tools) do
        local name = item.label:sub(2)
        if vim.startswith(name:lower(), typed) then
          table.insert(items, {
            -- word without braces so Vim's prefix filter works while typing
            word = triggers.mappings.tools .. name,
            abbr = name,
            menu = item.detail or item.description,
            kind = "f",
            icase = 1,
            user_data = { needs_braces = true },
          })
        end
      end

    elseif trigger_char == triggers.mappings.slash_commands then
      local slash_cmds = completion.slash_commands()
      for _, item in ipairs(slash_cmds) do
        local name = item.label:sub(2)
        if vim.startswith(name:lower(), typed) then
          table.insert(items, {
            word = item.label,
            abbr = name,
            menu = item.detail or item.description,
            kind = "f",
            icase = 1,
            user_data = {
              command = name,
              label = item.label,
              type = item.type,
              config = item.config,
              from_prompt_library = item.from_prompt_library,
            },
          })
        end
      end
    end

    return items
  end
end

return M
