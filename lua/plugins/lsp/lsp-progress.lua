local M = {}

local success_icon = "󰄳 "
local spinner_end_keep = 2000 -- ms

local series = {}
local last_message = ""
local timer = vim.loop.new_timer()

local function clear()
  timer:stop()
  timer:start(
    spinner_end_keep,
    0,
    vim.schedule_wrap(function()
      last_message = ""
    end)
  )
end

local function log(msg)
  local client = msg.client or ""
  local title = msg.title or ""
  local message = msg.message or ""
  local percentage = msg.percentage or 0

  local out = ""

  if client ~= "" then
    out = string.format("%s%s%s%s", out, "[", client, "]")
  end
  -- if client ~= "" then
  --   -- out = out .. "[" .. client .. "]"
  --   out = string.format("%s%s%s%s", out, "[", client, "]")
  -- end

  if percentage > 0 then
    out = string.format("%s%s%d%%%%%s", out, "[", percentage, "]")
  end

  if title ~= "" then
    out = string.format("%s %s", out, title)
  end

  if message ~= "" then
    if title ~= "" and vim.startswith(message, title) then
      message = string.sub(message, string.len(title) + 1)
    end

    message = message:gsub("%s*%d+%%", "")
    message = message:gsub("^%s*-", "")
    message = vim.trim(message)
    if message ~= "" then
      if title ~= "" then
        out = out .. " - " .. message
      else
        out = out .. " " .. message
      end
    end
  end

  last_message = out
end

local function lsp_progress(err, progress, ctx)
  if err then
    return
  end

  local client = vim.lsp.get_client_by_id(ctx.client_id)
  local client_name = client and client.name or ""
  local token = progress.token
  local value = progress.value

  if value.kind == "begin" then
    series[token] = {
      client = client_name,
      title = value.title or "",
      message = value.message or "",
      percentage = value.percentage or 0,
    }

    local cur = series[token]
    log {
      client = cur.client,
      title = cur.title,
      message = cur.message .. " - Starting",
      percentage = cur.percentage,
    }
  elseif value.kind == "report" then
    local cur = series[token]
    log {
      client = client_name or (cur and cur.client),
      title = value.title or (cur and cur.title),
      message = value.message or (cur and cur.message),
      percentage = value.percentage or (cur and cur.percentage),
    }
  -- elseif value.kind == "end" then
  --   if vim.b.spinner_icon ~= spinner_icon_done and allow_changing_state() then
  --     vim.b.spinner_state_changed = now
  --     vim.b.spinner_icon = spinner_icon_done .. " " -- INFO: keep the space there
  --   end
  -- end
  elseif value.kind == "end" then
    local cur = series[token]
    log {
      client = client_name or (cur and cur.client),
      -- title = value.title or (cur and cur.title),
      message = success_icon .. " - Done",
      -- message = (value.message or (cur and cur.message)) .. ' - Done',
    }
    series[token] = nil
    clear()
  end
end

local old_handler = vim.lsp.handlers["$/progress"]
vim.lsp.handlers["$/progress"] = function(...)
  if old_handler then
    old_handler(...)
  end
  lsp_progress(...)
end

function M.message()
  return last_message
end

return M
