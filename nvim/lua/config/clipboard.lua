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

  vim.g.clipboard = {
    name = "herdr OSC 52",
    copy = {
      ["+"] = osc52.copy("+"),
      ["*"] = osc52.copy("*"),
    },
    paste = {
      ["+"] = osc52.paste("+"),
      ["*"] = osc52.paste("*"),
    },
  }

  -- In herdr, yanking a visual selection should publish it to the host clipboard.
  vim.opt.clipboard:append("unnamedplus")
end

return M
