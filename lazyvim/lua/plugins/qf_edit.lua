-- /Users/adam/.config/lazyvim/lua/plugins/qf_edit.lua
-- Tell Lazy to load the local plugin (no network). Loads only for quickfix/location lists.
return {
  {
    name = "qf-edit.nvim",  -- keep your preferred name
    dir = vim.fn.stdpath("config") .. "/local_plugins/qf_edit/", -- force local path
    ft = "qf",              -- load when a quickfix/location list opens
    -- no config needed: plugin/qf_edit.lua runs on load
  },
}
