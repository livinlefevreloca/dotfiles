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

      -- PSQL History commands
      local function has_octal_encoding(file)
        -- Check if file has octal sequences like \040
        local f = io.open(file, "r")
        if not f then return false end
        local content = f:read(8192) -- Read first 8KB
        f:close()
        return content and content:match("\\%d%d%d") ~= nil
      end

      local function decode_octal_file(input_file, output_file)
        -- Decode octal sequences in the file
        local inf = io.open(input_file, "r")
        if not inf then return false end

        local outf = io.open(output_file, "w")
        if not outf then
          inf:close()
          return false
        end

        for line in inf:lines() do
          -- Skip history markers
          if not line:match("^_HiStOrY_") then
            -- Decode octal sequences
            local decoded = line:gsub("\\(%d%d%d)", function(octal)
              return string.char(tonumber(octal, 8))
            end)
            -- Replace control character 1 (^A) with space for display
            -- Psql uses this for multi-line queries, but we want single-line for the list
            decoded = decoded:gsub(string.char(1), " ")
            -- Remove any other control characters
            decoded = decoded:gsub("[\002-\031]", " ")
            outf:write(decoded .. "\n")
          end
        end

        inf:close()
        outf:close()
        return true
      end

      local function search_psql_history(action)
        local Snacks = ensure_snacks(); if not Snacks then return end

        local history_file = vim.env.PSQL_HISTORY or (vim.env.HOME .. "/.psql_history")

        if not vim.fn.filereadable(history_file) == 1 then
          vim.notify("PSQL history file not found: " .. history_file, vim.log.levels.WARN)
          return
        end

        -- Check if we need to decode octal
        local search_file = history_file
        local temp_file = nil

        if has_octal_encoding(history_file) then
          temp_file = os.tmpname()
          if decode_octal_file(history_file, temp_file) then
            search_file = temp_file
          end
        end

        -- Read decoded file and create items
        local f = io.open(search_file, "r")
        if not f then
          vim.notify("Could not open history file", vim.log.levels.ERROR)
          if temp_file then pcall(os.remove, temp_file) end
          return
        end

        local items = {}
        for line in f:lines() do
          if line and line ~= "" then
            table.insert(items, { text = line })
          end
        end
        f:close()

        -- Reverse to show most recent first
        local reversed = {}
        for i = #items, 1, -1 do
          table.insert(reversed, items[i])
        end

        -- Use picker with items
        Snacks.picker({
          prompt = "PSQL History: ",
          finder = function()
            return reversed
          end,
          format = "text",
          preview = function(ctx)
            local item = ctx.item
            -- Format SQL in preview with pg_format
            if not item.text then
              return { text = "-- No query", ft = "sql" }
            end

            local cmd = string.format("echo -n %s pg_format 2>/dev/null", item.text)
            local handle = io.popen(cmd)
            if not handle then
              return { text = item.text, ft = "sql" }
            end

            local formatted = handle:read("*a")
            handle:close()

            return {
              text = formatted,
              ft = "sql",
            }
          end,
          on_close = function()
            -- Clean up temp file when picker closes
            if temp_file then
              pcall(os.remove, temp_file)
            end
          end,
          actions = {
            confirm = function(picker, item)
              if not item or not item.text then return end
              picker:close()

              local query = item.text

              vim.schedule(function()
                -- Clean up temp file
                if temp_file then
                  pcall(os.remove, temp_file)
                end

                if action == "clipboard" then
                  vim.fn.setreg("+", query)
                  vim.fn.setreg('"', query)
                  vim.notify("Query copied to clipboard", vim.log.levels.INFO)
                else
                  local current_buf = vim.api.nvim_get_current_buf()
                  local line_count = vim.api.nvim_buf_line_count(current_buf)
                  local query_lines = vim.split(query, "\n", { plain = true, trimempty = false })

                  vim.api.nvim_buf_set_lines(current_buf, line_count, line_count, false, query_lines)
                  vim.api.nvim_win_set_cursor(0, { line_count + 1, 0 })

                  vim.notify("Query pasted to buffer", vim.log.levels.INFO)
                end
              end)
            end,
          },
        })
      end

      vim.api.nvim_create_user_command("PsqlHist", function()
        search_psql_history("buffer")
      end, { desc = "Search PSQL history and paste to buffer" })

      vim.api.nvim_create_user_command("PsqlHistC", function()
        search_psql_history("clipboard")
      end, { desc = "Search PSQL history and copy to clipboard" })
    end,
  },
}
