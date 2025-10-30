vim.api.nvim_create_user_command("ToggleInlineDiagnostics", function()
  local current = vim.diagnostic.config().virtual_text
  vim.diagnostic.config({
    virtual_text = not current,
  })
  if current then
    vim.notify("Inline diagnostics disabled", vim.log.levels.INFO)
  else
    vim.notify("Inline diagnostics enabled", vim.log.levels.INFO)
  end
end, {})

-- Get a secret Version Id from aws given
vim.api.nvim_create_user_command('GetSecretId',
  function (opts)
    local on_exit = function(job_id, exit_code, event_type)
        print("Job " .. job_id .. " exited with code " .. exit_code)
    end
    
    local on_stdout = function(job_id, data, event_type)
        local result = ""
        if data then
          for _, line in ipairs(data) do
            result = result .. line
          end
          if result ~= "" then
            local json = vim.fn.json_decode(result)
            for k,v in pairs(json.VersionIdsToStages) do
              if v[1] == "AWSCURRENT" then
                print("Secret version ID: " .. k)
                vim.fn.setreg('a', k)
              end
            end
          end
        end
    end

    local on_stderr = function(job_id, data, event_type)
        if data then
            for _, line in ipairs(data) do
                if line ~= "" then
                    print("Job " .. job_id .. " erorr: " .. line)
                end
            end
        end
    end

    local secretPath =  vim.fn.expand('<cWORD>')
    print("Fetching secret ID for: " .. secretPath)

    local job = vim.fn.jobstart(
        {
          "aws",
          "secretsmanager",
          "describe-secret",
          "--secret-id",
          secretPath,
          "--profile",
          opts.fargs[1],
        },
        {
            cwd = '/Users/adam/',
            on_exit = on_exit,
            on_stdout = on_stdout,
            on_stderr = on_stderr
        }
    )
    vim.fn.jobwait({job}, 10000)
      
  end,
  {nargs = 1}
)

