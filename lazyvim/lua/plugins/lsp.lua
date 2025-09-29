return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      -- example: apply to all servers
      ["*"] = {
        on_attach = function(client, bufnr)
          -- disable document highlights
          client.server_capabilities.documentHighlightProvider = false
        end,
      },
    },
  },
}
