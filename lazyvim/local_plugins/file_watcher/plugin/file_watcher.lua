-- file_watcher.nvim - Auto-reload specified files on a timer with groups
--
-- Commands:
--   :WatchFiles [group] [interval_sec] <file1> <file2> ... - Start watching files in a group
--   :WatchStop [group]                                     - Stop watching group(s)
--   :WatchList                                             - Open editable watch list buffer
--   :WatchClear [group]                                    - Clear group(s) from watch list
--
-- Watch List Buffer Format:
--   [group_name] interval_seconds
--   /path/to/file1
--   /path/to/file2
--
--   [another_group] 5
--   /path/to/file3
--
-- Watch List Buffer Keymaps:
--   <CR> or w  - Save changes to watch list
--   q          - Close without saving
--   dd         - Delete line (remove file or group)
--   a          - Add file to current group interactively
--   A          - Add new group interactively

local M = {}

-- State: { [group_name] = { interval_ms = number, timer = timer_obj, files = { [filepath] = { mtime, bufnr } } } }
M.groups = {}
M.default_interval_ms = 10000  -- 10 seconds

-- Get file modification time
local function get_mtime(filepath)
  local stat = vim.loop.fs_stat(filepath)
  return stat and stat.mtime.sec or nil
end

-- Check if buffer is loaded for a file
local function get_buf_for_file(filepath)
  local bufnr = vim.fn.bufnr(filepath)
  if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
    return bufnr
  end
  return nil
end

-- Reload a buffer from disk
local function reload_buffer(bufnr, filepath)
  -- Save cursor position and view
  local view
  local current_win = vim.fn.bufwinid(bufnr)
  if current_win ~= -1 then
    vim.api.nvim_win_call(current_win, function()
      view = vim.fn.winsaveview()
    end)
  end

  -- Check if buffer has unsaved changes
  if vim.bo[bufnr].modified then
    vim.notify(
      string.format("Skipping reload of '%s' (unsaved changes)", vim.fn.fnamemodify(filepath, ":~")),
      vim.log.levels.WARN
    )
    return
  end

  -- Reload the buffer
  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd("edit!")
  end)

  -- Restore cursor position
  if view and current_win ~= -1 then
    vim.api.nvim_win_call(current_win, function()
      vim.fn.winrestview(view)
    end)
  end

  vim.notify(
    string.format("Reloaded: %s", vim.fn.fnamemodify(filepath, ":~")),
    vim.log.levels.INFO
  )
end

-- Poll function for a specific group
local function create_poll_function(group_name)
  return function()
    local group = M.groups[group_name]
    if not group then return end

    for filepath, data in pairs(group.files) do
      local current_mtime = get_mtime(filepath)

      if not current_mtime then
        -- File no longer exists
        vim.notify(
          string.format("[%s] File no longer exists: %s", group_name, vim.fn.fnamemodify(filepath, ":~")),
          vim.log.levels.WARN
        )
        group.files[filepath] = nil
      elseif current_mtime > data.mtime then
        -- File has been modified
        group.files[filepath].mtime = current_mtime

        -- Find buffer for this file
        local bufnr = get_buf_for_file(filepath)
        if bufnr then
          group.files[filepath].bufnr = bufnr
          reload_buffer(bufnr, filepath)
        end
      end
    end
  end
end

-- Start or update a group's timer
local function start_group_timer(group_name)
  local group = M.groups[group_name]
  if not group then return end

  -- Stop existing timer if running
  if group.timer then
    group.timer:stop()
    group.timer:close()
  end

  -- Start new timer
  group.timer = vim.loop.new_timer()
  group.timer:start(
    group.interval_ms,
    group.interval_ms,
    vim.schedule_wrap(create_poll_function(group_name))
  )
end

-- Stop a group's timer
local function stop_group_timer(group_name)
  local group = M.groups[group_name]
  if group and group.timer then
    group.timer:stop()
    group.timer:close()
    group.timer = nil
  end
end

-- Watch files in a specific group
function M.watch_files(group_name, interval_sec, files)
  -- Create group if it doesn't exist
  if not M.groups[group_name] then
    M.groups[group_name] = {
      interval_ms = interval_sec * 1000,
      timer = nil,
      files = {},
    }
  else
    -- Update interval if provided
    M.groups[group_name].interval_ms = interval_sec * 1000
  end

  local group = M.groups[group_name]
  local added_count = 0

  for _, file in ipairs(files) do
    -- Expand wildcards and ~
    local expanded = vim.fn.glob(file, false, true)

    for _, filepath in ipairs(expanded) do
      -- Convert to absolute path
      filepath = vim.fn.fnamemodify(filepath, ":p")

      local mtime = get_mtime(filepath)
      if mtime then
        if not group.files[filepath] then
          group.files[filepath] = {
            mtime = mtime,
            bufnr = get_buf_for_file(filepath),
          }
          added_count = added_count + 1
          vim.notify(
            string.format("[%s] Watching: %s", group_name, vim.fn.fnamemodify(filepath, ":~")),
            vim.log.levels.INFO
          )
        else
          vim.notify(
            string.format("[%s] Already watching: %s", group_name, vim.fn.fnamemodify(filepath, ":~")),
            vim.log.levels.WARN
          )
        end
      else
        vim.notify(
          string.format("[%s] File not found: %s", group_name, file),
          vim.log.levels.ERROR
        )
      end
    end
  end

  -- Start or restart timer
  if added_count > 0 or not group.timer then
    start_group_timer(group_name)
    vim.notify(
      string.format("[%s] Polling every %d seconds", group_name, interval_sec),
      vim.log.levels.INFO
    )
  end

  if added_count == 0 and #files > 0 then
    vim.notify(
      string.format("[%s] No new files added", group_name),
      vim.log.levels.WARN
    )
  end
end

-- Stop watching a group or all groups
function M.stop_watching(group_name)
  if group_name then
    if M.groups[group_name] then
      stop_group_timer(group_name)
      vim.notify(string.format("[%s] Stopped watching", group_name), vim.log.levels.INFO)
    else
      vim.notify(string.format("[%s] Group not found", group_name), vim.log.levels.WARN)
    end
  else
    -- Stop all groups
    for name, _ in pairs(M.groups) do
      stop_group_timer(name)
    end
    vim.notify("Stopped all watch groups", vim.log.levels.INFO)
  end
end

-- Clear a group or all groups
function M.clear_watch_list(group_name)
  if group_name then
    if M.groups[group_name] then
      stop_group_timer(group_name)
      M.groups[group_name] = nil
      vim.notify(string.format("[%s] Cleared", group_name), vim.log.levels.INFO)
    else
      vim.notify(string.format("[%s] Group not found", group_name), vim.log.levels.WARN)
    end
  else
    -- Clear all groups
    for name, _ in pairs(M.groups) do
      stop_group_timer(name)
    end
    M.groups = {}
    vim.notify("Cleared all watch groups", vim.log.levels.INFO)
  end
end

-- Parse and apply changes from the watch list buffer
local function apply_watch_list(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local new_groups = {}
  local current_group = nil
  local current_interval = nil

  for _, line in ipairs(lines) do
    local trimmed = vim.trim(line)

    -- Skip empty lines and comments
    if trimmed == "" or trimmed:match("^#") or trimmed:match("^%-%-") then
      goto continue
    end

    -- Check for group header: [group_name] interval_seconds
    local group_match, interval_match = trimmed:match("^%[([^%]]+)%]%s*(%d+%.?%d*)$")
    if group_match and interval_match then
      current_group = group_match
      current_interval = tonumber(interval_match) * 1000
      new_groups[current_group] = {
        interval_ms = current_interval,
        timer = nil,
        files = {},
      }
      goto continue
    end

    -- File path line (must have a current group)
    if current_group then
      local filepath = vim.fn.expand(trimmed)
      filepath = vim.fn.fnamemodify(filepath, ":p")

      local mtime = get_mtime(filepath)
      if mtime then
        new_groups[current_group].files[filepath] = {
          mtime = mtime,
          bufnr = get_buf_for_file(filepath),
        }
      else
        vim.notify(
          string.format("[%s] File not found (removed): %s", current_group, trimmed),
          vim.log.levels.WARN
        )
      end
    else
      vim.notify(
        string.format("File without group header (ignored): %s", trimmed),
        vim.log.levels.WARN
      )
    end

    ::continue::
  end

  -- Stop all existing timers
  for name, _ in pairs(M.groups) do
    stop_group_timer(name)
  end

  -- Update groups
  M.groups = new_groups

  -- Start timers for groups with files
  local total_files = 0
  for name, group in pairs(M.groups) do
    local file_count = vim.tbl_count(group.files)
    if file_count > 0 then
      start_group_timer(name)
      total_files = total_files + file_count
    end
  end

  if total_files == 0 then
    vim.notify("Watch list is now empty", vim.log.levels.INFO)
  else
    local group_count = vim.tbl_count(M.groups)
    vim.notify(
      string.format(
        "Watch list updated: %d group%s, %d file%s",
        group_count,
        group_count == 1 and "" or "s",
        total_files,
        total_files == 1 and "" or "s"
      ),
      vim.log.levels.INFO
    )
  end

  -- Mark buffer as unmodified
  vim.bo[bufnr].modified = false
end

-- Setup keymaps for watch list buffer
local function setup_watch_list_keymaps(bufnr)
  local opts = { buffer = bufnr, silent = true }

  -- Save changes
  vim.keymap.set("n", "<CR>", function()
    apply_watch_list(bufnr)
  end, vim.tbl_extend("force", opts, { desc = "Apply watch list changes" }))

  vim.keymap.set("n", "w", function()
    apply_watch_list(bufnr)
  end, vim.tbl_extend("force", opts, { desc = "Apply watch list changes" }))

  -- Close buffer
  vim.keymap.set("n", "q", function()
    vim.cmd("quit")
  end, vim.tbl_extend("force", opts, { desc = "Close watch list" }))

  -- Delete current line
  vim.keymap.set("n", "dd", "dd", vim.tbl_extend("force", opts, { desc = "Delete line" }))

  -- Add file to current group
  vim.keymap.set("n", "a", function()
    vim.ui.input({ prompt = "Add file to watch: ", completion = "file" }, function(input)
      if input and input ~= "" then
        local cursor = vim.api.nvim_win_get_cursor(0)
        vim.api.nvim_buf_set_lines(bufnr, cursor[1], cursor[1], false, { input })
      end
    end)
  end, vim.tbl_extend("force", opts, { desc = "Add file to current group" }))

  -- Add new group
  vim.keymap.set("n", "A", function()
    vim.ui.input({ prompt = "Group name: " }, function(group_name)
      if not group_name or group_name == "" then return end
      vim.ui.input({ prompt = "Interval (seconds): ", default = "10" }, function(interval)
        if not interval or interval == "" then return end
        local new_lines = {
          "",
          string.format("[%s] %s", group_name, interval),
        }
        local cursor = vim.api.nvim_win_get_cursor(0)
        vim.api.nvim_buf_set_lines(bufnr, cursor[1], cursor[1], false, new_lines)
      end)
    end)
  end, vim.tbl_extend("force", opts, { desc = "Add new group" }))
end

-- Open editable watch list buffer
function M.list_watched()
  -- Create a new buffer
  local bufnr = vim.api.nvim_create_buf(false, true)

  -- Build content
  local lines = {
    "# Watch List - Edit and press <CR> or 'w' to save",
    "# Format:",
    "#   [group_name] interval_seconds",
    "#   /path/to/file1",
    "#   /path/to/file2",
    "#",
    "# Keymaps:",
    "#   <CR>/w - Save changes",
    "#   q      - Close without saving",
    "#   dd     - Delete line",
    "#   a      - Add file to current group",
    "#   A      - Add new group",
    "",
  }

  -- Add groups (sorted by name)
  local sorted_groups = {}
  for name, _ in pairs(M.groups) do
    table.insert(sorted_groups, name)
  end
  table.sort(sorted_groups)

  if #sorted_groups == 0 then
    table.insert(lines, "# No groups are currently being watched")
    table.insert(lines, "")
    table.insert(lines, "[default] 10")
  else
    for i, name in ipairs(sorted_groups) do
      local group = M.groups[name]
      local interval_sec = group.interval_ms / 1000

      -- Add group header
      table.insert(lines, string.format("[%s] %g", name, interval_sec))

      -- Add files (sorted)
      local sorted_files = {}
      for filepath, _ in pairs(group.files) do
        table.insert(sorted_files, filepath)
      end
      table.sort(sorted_files)

      for _, filepath in ipairs(sorted_files) do
        table.insert(lines, vim.fn.fnamemodify(filepath, ":~"))
      end

      -- Add blank line between groups (except after last)
      if i < #sorted_groups then
        table.insert(lines, "")
      end
    end
  end

  -- Set buffer content
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  -- Set buffer options
  vim.bo[bufnr].buftype = "acwrite"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].filetype = "watchlist"
  vim.bo[bufnr].modified = false

  -- Set buffer name
  vim.api.nvim_buf_set_name(bufnr, "[Watch List]")

  -- Setup autocmd for writing
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = bufnr,
    callback = function()
      apply_watch_list(bufnr)
    end,
    desc = "Save watch list changes",
  })

  -- Open in a split
  vim.cmd("split")
  vim.api.nvim_win_set_buf(0, bufnr)

  -- Setup keymaps
  setup_watch_list_keymaps(bufnr)

  -- Show help message
  vim.notify("Edit watch list | <CR>/w=save | q=close | dd=delete | a=add file | A=add group", vim.log.levels.INFO)
end

-- Create user commands
vim.api.nvim_create_user_command("WatchFiles", function(opts)
  local args = opts.fargs
  if #args < 1 then
    vim.notify("Usage: :WatchFiles [group] [interval_sec] <file1> <file2> ...", vim.log.levels.ERROR)
    return
  end

  local group_name = "default"
  local interval_sec = M.default_interval_ms / 1000
  local files = {}

  -- Parse arguments
  -- Format 1: :WatchFiles file1 file2 ... (use default group and interval)
  -- Format 2: :WatchFiles group_name file1 file2 ... (use custom group, default interval)
  -- Format 3: :WatchFiles group_name interval_sec file1 file2 ... (use custom group and interval)

  local first_arg = args[1]
  local second_arg = args[2]
  local starts_at = 1

  -- Check if first arg is a number (interval) or file
  local first_is_number = tonumber(first_arg) ~= nil
  local second_is_number = second_arg and tonumber(second_arg) ~= nil

  if second_is_number then
    -- Format 3: group interval files...
    group_name = first_arg
    interval_sec = tonumber(second_arg)
    starts_at = 3
  elseif first_is_number then
    -- Format: interval files... (use default group)
    interval_sec = tonumber(first_arg)
    starts_at = 2
  elseif #args >= 2 and not vim.fn.filereadable(vim.fn.expand(first_arg)) == 1 then
    -- Format 2: group files... (first arg doesn't look like a file)
    -- This is a heuristic - if the first arg isn't a readable file, assume it's a group name
    group_name = first_arg
    starts_at = 2
  end

  -- Collect remaining args as files
  for i = starts_at, #args do
    table.insert(files, args[i])
  end

  if #files == 0 then
    vim.notify("No files specified", vim.log.levels.ERROR)
    return
  end

  M.watch_files(group_name, interval_sec, files)
end, {
  nargs = "+",
  complete = "file",
  desc = "Watch files for changes in a group with specified interval",
})

vim.api.nvim_create_user_command("WatchStop", function(opts)
  local group_name = opts.fargs[1]
  M.stop_watching(group_name)
end, {
  nargs = "?",
  desc = "Stop watching a group (or all groups if no arg)",
})

vim.api.nvim_create_user_command("WatchClear", function(opts)
  local group_name = opts.fargs[1]
  M.clear_watch_list(group_name)
end, {
  nargs = "?",
  desc = "Clear a group from watch list (or all groups if no arg)",
})

vim.api.nvim_create_user_command("WatchList", function()
  M.list_watched()
end, {
  desc = "Open editable watch list buffer",
})

-- Clean up on exit
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    for name, _ in pairs(M.groups) do
      stop_group_timer(name)
    end
  end,
  desc = "Stop all file watchers on exit",
})

return M
