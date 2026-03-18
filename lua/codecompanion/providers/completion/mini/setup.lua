local config = require("codecompanion.config")
local triggers = require("codecompanion.triggers")

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "codecompanion", "codecompanion_input" },
  callback = function(args)
    local bufnr = args.buf

    vim.bo[bufnr].completefunc = "v:lua.require'codecompanion.providers.completion.mini'.completefunc"

    vim.b[bufnr].minicompletion_config = {
      lsp_completion = {
        source_func = "completefunc",
        auto_setup = false,
      },
    }

    local trigger_chars = {
      triggers.mappings.slash_commands,
      triggers.mappings.tools,
      triggers.mappings.editor_context,
    }
    if config.interactions.chat.slash_commands.opts.acp.enabled then
      table.insert(trigger_chars, triggers.mappings.acp_slash_commands)
    end

    vim.api.nvim_create_autocmd("InsertCharPre", {
      buffer = bufnr,
      callback = function()
        if vim.tbl_contains(trigger_chars, vim.v.char) then
          vim.schedule(function()
            vim.api.nvim_feedkeys(vim.keycode("<C-x><C-u>"), "n", false)
          end)
        end
      end,
    })

    -- After selecting a tool or editor_context item, wrap the name in braces.
    -- The completefunc returns word without braces (e.g. "@tool_name") so that
    -- Vim's native prefix filter works while typing; this restores the braces.
    vim.api.nvim_create_autocmd("CompleteDone", {
      buffer = bufnr,
      callback = function()
        local item = vim.v.completed_item
        if type(item) ~= "table" then
          return
        end
        local user_data = item.user_data
        if type(user_data) ~= "table" or not user_data.needs_braces then
          return
        end

        local word = item.word
        if not word or #word < 2 then
          return
        end

        local trigger = word:sub(1, 1)
        local name = word:sub(2)
        local with_braces = string.format("%s{%s}", trigger, name)

        local row, col = unpack(vim.api.nvim_win_get_cursor(0))
        local line = vim.api.nvim_get_current_line()

        -- Find the inserted word ending at the cursor and replace it
        local before = line:sub(1, col)
        local start_idx = before:find(vim.pesc(word) .. "$")
        if start_idx then
          vim.api.nvim_buf_set_text(0, row - 1, start_idx - 1, row - 1, col, { with_braces })
          vim.api.nvim_win_set_cursor(0, { row, start_idx - 1 + #with_braces })
        end
      end,
    })

    return true -- remove this autocmd after first run
  end,
})
