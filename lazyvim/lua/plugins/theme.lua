return {
  {
    "Tsuzat/NeoSolarized.nvim",
    lazy = false, -- load at startup
    priority = 1000, -- ensure it loads early, before UI plugins
    config = function()
      local neosolarized = require("NeoSolarized")
      neosolarized.setup({
        style = "dark", -- or "light"
        transparent = false, -- true → don't set background
        terminal_colors = true, -- set the terminal color palette
        enable_italics = true,
        styles = {
          comments = { italic = true },
          keywords = { italic = false, bold = true },
          strings = { italic = false },
          -- etc.
        },
        on_highlights = function(hl, colors)
          -- hl: table of highlight groups
          -- colors: palette provided by NeoSolarized
          hl.Visual = {
            bg = colors.violet, -- pick any color from the palette
            fg = colors.base03, -- optional foreground override
          }
        end,
      })
      vim.cmd([[colorscheme NeoSolarized]])
    end,
  },
}
