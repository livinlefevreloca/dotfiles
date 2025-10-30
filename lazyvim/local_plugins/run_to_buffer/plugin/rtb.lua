  local function open_scratch(title)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
    vim.api.nvim_buf_set_option(buf, "swapfile", false)
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    vim.api.nvim_buf_set_name(buf, title)

    vim.cmd("belowright split")
    vim.api.nvim_win_set_buf(0, buf)
    vim.api.nvim_win_set_option(0, "wrap", false)

    vim.keymap.set("n", "q", function()
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end, { buffer = buf, nowait = true, silent = true, desc = "Close output buffer" })

    return buf
  end

  local last_shell_cmd = nil
  local modifiable = false

  local function expand_modifiers(cmd)
    -- Expand % and # style file modifiers (like :! does)
    -- Uses the same mechanism as the command-line expansion
    local expanded = vim.fn.expandcmd(cmd)
    return expanded
  end

  local function run_to_buffer(cmd)
    if not cmd or cmd == "" then
      vim.notify("RunToBuffer: empty command", vim.log.levels.WARN)
      return
    end

    cmd = expand_modifiers(cmd)
    last_shell_cmd = cmd

    local buf = open_scratch("cmd://" .. cmd)

    local function append(lines, prefix)
      if not lines or vim.tbl_isempty(lines) then
        return
      end
      local out = {}
      for _, s in ipairs(lines) do
        if s ~= "" then
          s = s:gsub("\r$", ""):gsub("%z", "")
          table.insert(out, prefix and (prefix .. s) or s)
        end
      end
      if #out > 0 and vim.api.nvim_buf_is_valid(buf) then
        local last = vim.api.nvim_buf_line_count(buf)
        vim.api.nvim_buf_set_lines(buf, last, last, false, out)
      end
    end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "⏳ Running: " .. cmd, "" })

    local jobid = vim.fn.jobstart({ "bash", "-lc", cmd }, {
      stdout_buffered = false,
      stderr_buffered = false,
      on_stdout = function(_, data)
        append(data, nil)
      end,
      on_stderr = function(_, data)
        append(data, "[stderr] ")
      end,
      on_exit = function(_, code)
        append({ "", "——", ("Exit code: %d"):format(code) })
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_set_option(buf, "modifiable", modifiable)
        end
      end,
    })

    if jobid <= 0 then
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "Failed to start job: " .. cmd })
    end
  end

  vim.api.nvim_create_user_command("RunToBuffer", function(opts)
    run_to_buffer(opts.args)
  end, { nargs = "*", complete = "shellcmd", desc = "Run shell command to buffer (q to close)" })

  -- Intercept :! and expand file modifiers
  vim.keymap.set("c", "<CR>", function()
    if vim.fn.getcmdtype() == ":" then
      local line = vim.fn.getcmdline()
      if line:sub(1, 1) == "!" then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-c>", true, false, true), "n", false)
        local raw = line:sub(2)
        local cmd = raw:gsub("^%s+", "")

        vim.schedule(function()
          if cmd == "!" then
            if last_shell_cmd and last_shell_cmd ~= "" then
              run_to_buffer(last_shell_cmd)
            else
              vim.notify("No previous :! command", vim.log.levels.WARN)
            end
          else
            run_to_buffer(cmd)
          end
        end)

        return ""
      end
    end
    return vim.api.nvim_replace_termcodes("<CR>", true, false, true)
  end, { expr = true, silent = true, desc = "Route :! to RunToBuffer (deferred)" })

  vim.cmd([[
    cnoreabbrev <expr> ! getcmdtype()==':' && getcmdline()=='' ? '! ' : '!'
  ]])

  vim.keymap.set("n", "<leader>rm", function()
    modifiable = not modifiable
    vim.notify(("RunToBuffer: modifiable output %s"):format(modifiable and "enabled" or "disabled"), vim.log.levels.INFO)
  end, { desc = "Toggle modifiable output", silent = true })
