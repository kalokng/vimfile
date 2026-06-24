local M = {}

local function is_herdr()
  return vim.env.HERDR_ENV == "1"
end

function M.setup()
  if not is_herdr() then
    return
  end

  local ok, osc52 = pcall(require, "vim.ui.clipboard.osc52")
  if not ok then
    vim.notify("Neovim's OSC 52 clipboard provider is unavailable", vim.log.levels.WARN)
    return
  end

  local copied = {}

  local function copy(reg)
    local osc52_copy = osc52.copy(reg)

    return function(lines, regtype)
      copied[reg] = { lines = vim.deepcopy(lines), regtype = regtype }
      osc52_copy(lines, regtype)
    end
  end

  local function paste(reg)
    return function()
      local cached = copied[reg]
      if not cached then
        return 0
      end

      return cached.lines
    end
  end

  vim.g.clipboard = {
    name = "herdr OSC 52",
    copy = {
      ["+"] = copy("+"),
      ["*"] = copy("*"),
    },
    -- Neovim requires a paste provider, but OSC52 paste sends a terminal query
    -- and can block in herdr. Return only this session's cached register writes.
    paste = {
      ["+"] = paste("+"),
      ["*"] = paste("*"),
    },
  }
end

return M
