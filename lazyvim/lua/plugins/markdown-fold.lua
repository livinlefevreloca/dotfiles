-- Progressive bullet folding for markdown.
-- `zb` folds everything indented beneath the current line so only that line
-- (and its less/equally-indented ancestors) stays visible. `zb` on a closed
-- fold opens it again. Buffer-local to markdown files only.

-- Toggle a fold covering the current line and all more-indented lines below it.
local function toggle_bullet_fold()
  local lnum = vim.fn.line(".")

  -- On a closed fold: open it.
  if vim.fn.foldclosed(lnum) ~= -1 then
    vim.cmd("normal! zo")
    return
  end

  -- `:fold` requires a manual foldmethod; switch lazily (drops treesitter folds
  -- for this buffer, but only once the user actually starts folding bullets).
  if vim.wo.foldmethod ~= "manual" then
    vim.wo.foldmethod = "manual"
  end

  local last = vim.fn.line("$")
  local base = vim.fn.indent(lnum)
  local fold_end = lnum

  -- Walk downward, absorbing more-indented lines. Blank lines are tentative:
  -- they only join the fold if more indented content follows them.
  local l = lnum + 1
  while l <= last do
    local line = vim.fn.getline(l)
    if line:match("^%s*$") then
      -- blank: keep scanning without committing to the fold
    elseif vim.fn.indent(l) > base then
      fold_end = l
    else
      break
    end
    l = l + 1
  end

  if fold_end > lnum then
    vim.cmd(string.format("%d,%dfold", lnum, fold_end))
  end
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("markdown_bullet_fold", { clear = true }),
  pattern = "markdown",
  callback = function(ev)
    vim.keymap.set("n", "zb", toggle_bullet_fold, {
      buffer = ev.buf,
      desc = "Fold bullet children (toggle)",
    })
  end,
})

return {}
