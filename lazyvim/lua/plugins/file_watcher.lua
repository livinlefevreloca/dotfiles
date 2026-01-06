-- file_watcher.nvim - Auto-reload specified files on a timer with groups
--
-- Groups allow organizing files with different polling intervals.
-- Each group maintains its own timer and can be managed independently.
--
-- Usage:
--   :WatchFiles [group] [interval_sec] <file1> <file2> ...
--     - Default: :WatchFiles file.txt (default group, 10sec interval)
--     - With group: :WatchFiles logs 5 /var/log/app.log
--     - With interval: :WatchFiles 5 file.txt (default group, 5sec interval)
--
--   :WatchStop [group]   - Stop watching group (or all if no arg)
--   :WatchClear [group]  - Clear group (or all if no arg)
--   :WatchList           - Open editable watch list buffer
--
-- Watch List Buffer:
--   Format:
--     [group_name] interval_seconds
--     /path/to/file1
--     /path/to/file2
--
--     [another_group] 5
--     /path/to/file3
--
--   Keymaps:
--     <CR> or w  - Save changes and restart timers
--     q          - Close without saving
--     dd         - Delete line (remove file or entire group)
--     a          - Add file to current group
--     A          - Add new group with custom interval
--
-- Examples:
--   " Quick start - watch log file every 10 seconds
--   :WatchFiles /var/log/app.log
--
--   " Watch logs group every 5 seconds
--   :WatchFiles logs 5 /var/log/*.log
--
--   " Watch config files every 2 seconds
--   :WatchFiles configs 2 ~/.config/nvim/*.lua
--
--   " Edit all groups and intervals in buffer
--   :WatchList
--
--   " Stop specific group
--   :WatchStop logs
--
--   " Clear all groups
--   :WatchClear

return {
  {
    name = "file_watcher.nvim",
    dir = vim.fn.stdpath("config") .. "/local_plugins/file_watcher/",
    event = "VeryLazy",
  },
}
