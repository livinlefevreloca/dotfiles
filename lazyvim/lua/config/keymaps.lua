-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.api.nvim_set_keymap('n', '<leader>k',  '[<space>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>j',  ']<space>', {noremap = true, silent = true})

vim.api.nvim_set_keymap('n', '<leader>.',  ':echo pressed .', {noremap = true})

-- Show diagnostics in a floating window
local diagnostic_float_win = nil
local diagnostic_float_buf = nil
local diagnostic_source_buf = nil
local diagnostic_autocmd = nil

local function close_diagnostic_float()
  if diagnostic_float_win and vim.api.nvim_win_is_valid(diagnostic_float_win) then
    vim.api.nvim_win_close(diagnostic_float_win, true)
  end
  if diagnostic_autocmd then
    vim.api.nvim_del_autocmd(diagnostic_autocmd)
    diagnostic_autocmd = nil
  end
  diagnostic_float_win = nil
  diagnostic_float_buf = nil
  diagnostic_source_buf = nil
end

local function show_diagnostic_float()
  -- Close any existing float
  close_diagnostic_float()

  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  local diagnostics = vim.diagnostic.get(0, { lnum = line })

  if #diagnostics == 0 then
    vim.notify("No diagnostics on this line", vim.log.levels.INFO)
    return
  end

  -- Format diagnostics and track highlights
  local lines = {}
  local highlights = {}  -- { line_num, hl_group }

  for i, diag in ipairs(diagnostics) do
    local severity = vim.diagnostic.severity[diag.severity]
    local message = diag.message:gsub("\r\n", "\n"):gsub("\r", "\n")

    -- Get highlight group for severity
    local hl_group = "DiagnosticError"
    if diag.severity == vim.diagnostic.severity.WARN then
      hl_group = "DiagnosticWarn"
    elseif diag.severity == vim.diagnostic.severity.INFO then
      hl_group = "DiagnosticInfo"
    elseif diag.severity == vim.diagnostic.severity.HINT then
      hl_group = "DiagnosticHint"
    end

    -- Split message on newlines and add each line
    local msg_lines = vim.split(message, "\n", { plain = true })
    local start_line = #lines
    table.insert(lines, string.format("[%s] %s", severity, msg_lines[1]))
    table.insert(highlights, { line = start_line, hl_group = hl_group })

    for j = 2, #msg_lines do
      table.insert(lines, "    " .. msg_lines[j])
      table.insert(highlights, { line = #lines - 1, hl_group = hl_group })
    end

    if i < #diagnostics then
      table.insert(lines, "")
    end
  end

  -- Create floating window
  diagnostic_float_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(diagnostic_float_buf, 0, -1, false, lines)

  -- Apply highlights
  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(diagnostic_float_buf, -1, hl.hl_group, hl.line, 0, -1)
  end

  vim.api.nvim_set_option_value('modifiable', false, { buf = diagnostic_float_buf })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = diagnostic_float_buf })

  local width = 0
  for _, line_text in ipairs(lines) do
    width = math.max(width, #line_text)
  end
  width = math.min(width, vim.o.columns - 4)

  local opts = {
    relative = 'cursor',
    row = 1,
    col = 0,
    width = width,
    height = #lines,
    style = 'minimal',
    border = 'rounded',
  }

  diagnostic_float_win = vim.api.nvim_open_win(diagnostic_float_buf, false, opts)
  diagnostic_source_buf = vim.api.nvim_get_current_buf()

  -- Set up keymap to close on 'q'
  vim.api.nvim_buf_set_keymap(diagnostic_float_buf, 'n', 'q', '', {
    noremap = true,
    silent = true,
    callback = close_diagnostic_float,
  })

  -- Close when cursor moves in the source buffer
  diagnostic_autocmd = vim.api.nvim_create_autocmd('CursorMoved', {
    buffer = diagnostic_source_buf,
    callback = close_diagnostic_float,
    once = true,
  })
end

vim.keymap.set('n', '<leader>t', show_diagnostic_float, { noremap = true, silent = true, desc = "Show diagnostic float" })
