-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
--
-- Change *global* cwd to the file's directory on buffer switch
-- Disable with: nvim --cmd "let g:no_auto_chdir=1"
if not vim.g.no_auto_chdir then
  vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("AutoChdirOnBufEnter", { clear = true }),
    callback = function(args)
      local buf = args.buf
      if vim.bo[buf].buftype ~= "" then return end     -- skip help/terminal/etc.
      local name = vim.api.nvim_buf_get_name(buf)
      if name == "" then return end                    -- skip [No Name]
      local dir = vim.fn.fnamemodify(name, ":p:h")
      if dir ~= "" then vim.fn.chdir(dir) end          -- use global :cd
    end,
    desc = "Set cwd to current buffer's directory",
  })
end

-- Auto-reload files when changed on disk
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = vim.api.nvim_create_augroup("AutoReloadFiles", { clear = true }),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
  desc = "Reload files when changed on disk",
})

-- Remove trailing whitespace on save
-- Disable with: nvim --cmd "let g:no_trim_whitespace=1"
if not vim.g.no_trim_whitespace then
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("RemoveTrailingWhitespace", { clear = true }),
    callback = function()
      -- Save cursor position
      local cursor_pos = vim.api.nvim_win_get_cursor(0)
      -- Remove trailing whitespace
      vim.cmd([[%s/\s\+$//e]])
      -- Restore cursor position
      vim.api.nvim_win_set_cursor(0, cursor_pos)
    end,
    desc = "Remove trailing whitespace before saving",
  })
end
