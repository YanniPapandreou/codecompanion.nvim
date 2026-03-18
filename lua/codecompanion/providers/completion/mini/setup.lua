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

    return true -- remove this autocmd after first run
  end,
})
