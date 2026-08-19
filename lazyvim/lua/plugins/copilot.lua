return {
  -- Keep Copilot installed but disabled by default.
  --
  -- Copilot can suggest via two paths in this config:
  --   1. Inline ghost-text  (copilot.lua attaching to the buffer)
  --   2. The blink.cmp completion menu (via the `blink-copilot` source)
  -- Both are disabled below. Re-enable manually with `:Copilot! attach`.

  -- Path 1: don't auto-attach copilot.lua to any buffer.
  {
    "zbirenbaum/copilot.lua",
    opts = function(_, opts)
      opts.should_attach = function()
        return false
      end
    end,
  },

  -- Path 2: drop the copilot source from blink.cmp.
  {
    "saghen/blink.cmp",
    optional = true,
    opts = function(_, opts)
      local sources = opts.sources or {}
      if type(sources.default) == "table" then
        sources.default = vim.tbl_filter(function(name)
          return name ~= "copilot"
        end, sources.default)
      end
      if sources.providers then
        sources.providers.copilot = nil
      end
    end,
  },
}
