return {
  {
    -- We attach our command/keymap to Snacks itself without changing its opts.
    "folke/snacks.nvim",
    optional = true, -- don't force-install/enable; works only if you use Snacks
    keys = {
      {
        "<leader>ff",
        function()
          local ok, Snacks = pcall(require, "snacks")
          if not ok then return end
          Snacks.picker.files({ cwd = vim.fn.getcwd(), follow = true, hidden = true, git_ignore = true })
        end,
        desc = "Find Files (CWD via Snacks)",
      },
      { "<leader>fF", "<cmd>ProjectFiles<cr>", desc = "Project Files (Snacks)" },
      { "<leader>sg", "<cmd>GrepCwd<cr>", desc = "Grep (CWD via Snacks)" },
      { "<leader>sG", "<cmd>GrepProject<cr>", desc = "Grep (Git root fallback to CWD)" },
    },
    init = function()
      local function git_root_or_cwd()
        if vim.system then
          local res = vim.system({ "git", "rev-parse", "--show-toplevel" }, { text = true }):wait()
          if res and res.code == 0 and res.stdout and #res.stdout > 0 then
            return (res.stdout:gsub("%s+$", ""))
          end
        else
          local out = vim.fn.systemlist("git rev-parse --show-toplevel")
          if vim.v.shell_error == 0 and #out > 0 then
            return out[1]
          end
        end
        return (vim.uv and vim.uv.cwd()) or vim.fn.getcwd()
      end

      local function ensure_snacks()
        local ok, Snacks = pcall(require, "snacks")
        if ok then return Snacks end
        local ok_lazy, lazy = pcall(require, "lazy")
        if ok_lazy then
          lazy.load({ plugins = { "snacks.nvim" } })
          ok, Snacks = pcall(require, "snacks")
        end
        if not ok then
          vim.notify("Snacks not available", vim.log.levels.WARN)
          return nil
        end
        return Snacks
      end

      vim.api.nvim_create_user_command("ProjectFiles", function()
        -- Try to require Snacks; if missing, ask Lazy to load it, then require again.
        local Snacks = ensure_snacks(); if not Snacks then return end
        Snacks.picker.files({
          cwd = git_root_or_cwd(),
          hidden = true,
          git_ignore = true,
          follow = true,
        })
      end, { desc = "Snacks: files at git root (fallback to CWD)" })

      vim.api.nvim_create_user_command("GrepCwd", function()
        local Snacks = ensure_snacks(); if not Snacks then return end
        Snacks.picker.grep({
          cwd = vim.fn.getcwd(),  -- respects lcd/tcd/global
          hidden = true,
          git_ignore = true,
          follow = true,
        })
      end, { desc = "Snacks: Grep in current working directory" })

      vim.api.nvim_create_user_command("GrepProject", function()
        local Snacks = ensure_snacks(); if not Snacks then return end
        Snacks.picker.grep({
          cwd = git_root_or_cwd(), -- git top-level, fallback to CWD
          hidden = true,
          git_ignore = true,
          follow = true,
        })
      end, { desc = "Snacks: Grep in git root (fallback CWD)" })
    end,
  },
}
