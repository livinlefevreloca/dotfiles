-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.g.mapleader = ","
vim.g.autoformat = false

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    pcall(require, "config.commands")  -- this file defines ToggleInlineDiagnostics

    -- Disable inline diagnostics by default (after LazyVim loads)
    vim.diagnostic.config({
      virtual_text = false,
    })
  end,
})
