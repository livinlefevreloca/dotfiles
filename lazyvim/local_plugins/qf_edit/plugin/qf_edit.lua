-- Quickfix & location list editor: delete/move/edit/filter/dedupe

local function is_loclist()
  local win = vim.api.nvim_get_current_win()
  local info = (vim.fn.getwininfo(win) or {})[1] or {}
  return info.loclist == 1
end

local function get_list()
  return is_loclist() and vim.fn.getloclist(0) or vim.fn.getqflist()
end

local function set_list(list, action)
  action = action or "r"
  if is_loclist() then
    vim.fn.setloclist(0, list, action)
  else
    vim.fn.setqflist(list, action)
  end
end

local function current_index()
  if is_loclist() then
    return vim.fn.getloclist(0, { idx = 0 }).idx
  else
    return vim.fn.getqflist({ idx = 0 }).idx
  end
end

local function set_cursor_idx(i)
  vim.api.nvim_win_set_cursor(0, { math.max(i, 1), 0 })
end

local M = {}

function M.delete_current()
  local idx = current_index()
  local list = get_list()
  if list[idx] then
    table.remove(list, idx)
    set_list(list, "r")
    set_cursor_idx(math.min(idx, #list))
  end
end

function M.move(delta)
  local idx = current_index()
  local list = get_list()
  local new_idx = math.max(1, math.min(#list, idx + delta))
  if new_idx ~= idx then
    local item = list[idx]
    table.remove(list, idx)
    table.insert(list, new_idx, item)
    set_list(list, "r")
    set_cursor_idx(new_idx)
  end
end

function M.edit_text()
  local idx = current_index()
  local list = get_list()
  local item = list[idx]
  if not item then return end
  local new = vim.fn.input("New text: ", item.text or "")
  if new ~= nil then
    list[idx].text = new
    set_list(list, "r")
    set_cursor_idx(idx)
  end
end

function M.edit_pos()
  local idx = current_index()
  local list = get_list()
  local it = list[idx]
  if not it then return end
  local lnum = tonumber(vim.fn.input("lnum: ", tostring(it.lnum or 1))) or it.lnum or 1
  local colstart  = tonumber(vim.fn.input("col start:  ", tostring(it.col or 1))) or it.col or 1
  local colend = tonumber(vim.fn.input("col end:  ", tostring(it.col or 1))) or it.col or 1
  it.lnum, it.col, it.end_col = lnum, colstart, colend
  set_list(list, "r")
  set_cursor_idx(idx)
end

function M.filter_keep()
  local pat = vim.fn.input("Keep (Lua pattern): ")
  if not pat or pat == "" then return end
  local list = get_list()
  local filtered = vim.tbl_filter(function(x)
    return tostring(x.text or ""):match(pat) ~= nil
  end, list)
  set_list(filtered, "r")
  set_cursor_idx(1)
end

function M.filter_drop()
  local pat = vim.fn.input("Drop (Lua pattern): ")
  if not pat or pat == "" then return end
  local list = get_list()
  local filtered = vim.tbl_filter(function(x)
    return tostring(x.text or ""):match(pat) == nil
  end, list)
  set_list(filtered, "r")
  set_cursor_idx(1)
end

function M.dedupe()
  local list = get_list()
  local seen, out = {}, {}
  for _, it in ipairs(list) do
    local key = table.concat({
      it.bufnr or 0, it.lnum or 0, it.col or 0, it.end_lnum or 0, it.end_col or 0, it.type or "", it.text or ""
    }, ":")
    if not seen[key] then
      seen[key] = true
      table.insert(out, it)
    end
  end
  set_list(out, "r")
  set_cursor_idx(1)
end

-- Buffer-local keymaps in qf/loc windows
vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function()
    local map = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = true, silent = true, desc = desc })
    end
    map("dd", M.delete_current,         "QF: delete entry")
    map("J",  function() M.move(1) end, "QF: move entry down")
    map("K",  function() M.move(-1) end,"QF: move entry up")
    map("et", M.edit_text,              "QF: edit text")
    map("ep", M.edit_pos,               "QF: edit lnum/col")
    map("fk", M.filter_keep,            "QF: keep matches")
    map("fd", M.filter_drop,            "QF: drop matches")
    map("du", M.dedupe,                 "QF: dedupe entries")
    map("q",  "<cmd>cclose|lclose<CR>", "Close lists")
  end,
})
