local utils = require "utils.general"
local buffer = require "utils.buffer"
local augroup = utils.create_augroup
local groupid = vim.api.nvim_create_augroup("StatusLine", {})
local last_message = ""

local M = {}
-- local spinner_icons =
--   { ' ', '󰪞 ', '󰪟 ', '󰪠 ', '󰪢 ', '󰪣 ', '󰪤 ', '󰪥 ' }
-- local spinners = { "󰸶", "󰸸", "󰸷", "󰸴", "󰸵", "󰸳" }

local spinner_icons = { " ", " ", " ", "󰺕 ", " ", " " }
local success_icon = {
  "󰄳 ",
  "󰄳 ",
  "󰄳 ",
}

local function get_succes_frame()
  local ms = vim.loop.hrtime() / 1000000
  local frame = math.floor(ms / 120) % #success_icon
  return string.format(success_icon[frame + 1])
end

local spinner_end_keep = 2000 -- ms
local spinner_status_keep = 600 -- ms
local spinner_progress_keep = 80 -- ms

-- local spinner_icon_done = vim.trim(success_icon[1])
local spinner_icon_done = vim.trim(get_succes_frame())
local spinner_timer = vim.uv.new_timer()

---Id and additional info of language servers in progress
---@type table<integer, { name: string, timestamp: integer, progress: vim.Ringbuf, type: 'begin'|'report'|'end' }>
local server_info_in_progress = {}

-- local messages = {} --- @type string[]

local function log(msg)
  local client = msg.client or ""
  local title = msg.title or ""
  local message = msg.message or ""
  local percentage = msg.percentage or 0

  local out = ""

  if client ~= "" then
    out = string.format("%s%s%s%s", out, "[", client, "]")
  end

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

vim.api.nvim_create_autocmd("LspProgress", {
  desc = "Update LSP progress info for the status line.",
  group = groupid,
  callback = function(info)
    if spinner_timer then
      spinner_timer:start(spinner_progress_keep, spinner_progress_keep, vim.schedule_wrap(vim.cmd.redrawstatus))
    end

    local id = info.data.client_id
    local client = vim.lsp.get_client_by_id(id)
    local now = vim.uv.now()
    server_info_in_progress[id] = {
      name = client.name,
      progress = client.progress,
      timestamp = now,
      type = info.data.result.value.kind,
    } -- Update LSP progress data
    -- Clear client message after a short time if no new message is received
    vim.defer_fn(function()
      -- No new report since the timer was set
      local last_timestamp = (server_info_in_progress[id] or {}).timestamp
      if not last_timestamp or last_timestamp == now then
        server_info_in_progress[id] = nil
        if vim.tbl_isempty(server_info_in_progress) and spinner_timer then
          spinner_timer:stop()
        end
        vim.cmd.redrawstatus()
      end
    end, spinner_end_keep)
  end,
})

function M.lsp_progress()
  if vim.tbl_isempty(server_info_in_progress) then
    return ""
  end

  local buf = vim.api.nvim_get_current_buf()
  local server_ids = {}
  for id, _ in pairs(server_info_in_progress) do
    if vim.tbl_contains(vim.lsp.get_buffers_by_client_id(id), buf) then
      table.insert(server_ids, id)
    end
  end
  if vim.tbl_isempty(server_ids) then
    return ""
  end

  local now = vim.uv.now()
  ---@return boolean
  local function allow_changing_state()
    return not vim.b.spinner_state_changed or now - vim.b.spinner_state_changed > spinner_status_keep
  end

  local client = vim.lsp.get_client_by_id(server_ids[1])
  -- local progress = client.progress

  -- if server_info_in_progress[server_ids[1]].type == "report" then
  --   message = vim.lsp.status()
  -- end

  if #server_ids == 1 and server_info_in_progress[server_ids[1]].type == "end" then
    if vim.b.spinner_icon ~= spinner_icon_done and allow_changing_state() then
      vim.b.spinner_state_changed = now
      vim.b.spinner_icon = spinner_icon_done .. " " -- INFO: keep the space there
    end
  else
    local ms = vim.loop.hrtime() / 1000000
    local spinner_icon_progress = spinner_icons[math.floor(ms / 120) % #spinner_icons + 1]

    if vim.b.spinner_icon ~= spinner_icon_done then
      vim.b.spinner_icon = spinner_icon_progress
    elseif allow_changing_state() then
      vim.b.spinner_state_changed = now
      vim.b.spinner_icon = spinner_icon_progress
    end
  end

  return string.format(
    "%s %s %s",
    vim.b.spinner_icon,
    -- vim.lsp.status(),
    table.concat(
      vim.tbl_map(function(id)
        return server_info_in_progress[id].name
      end, server_ids),
      ", "
    )
  )
end

--- Consumes the latest progress messages from all clients and formats them as a string.
--- Empty if there are no clients or if no new messages
---
---@return string
function M.lsp_status()
  local percentage = nil
  local messages = {} --- @type string[]
  for _, client in ipairs(vim.lsp.get_clients()) do
    --- @diagnostic disable-next-line:no-unknown
    for progress in client.progress do
      --- @cast progress {token: lsp.ProgressToken, value: lsp.LSPAny}
      local value = progress.value
      if type(value) == "table" and value.kind then
        local message = value.message and (value.title .. ": " .. value.message) or value.title
        messages[#messages + 1] = message
        if value.percentage then
          percentage = math.max(percentage or 0, value.percentage)
        end
      end
      -- else: Doesn't look like work done progress and can be in any format
      -- Just ignore it as there is no sensible way to display it
    end
  end
  local message = table.concat(messages, ", ")
  if percentage then
    return string.format("%3d%%: %s", percentage, message)
  end
  return message
end

return M
