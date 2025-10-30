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
