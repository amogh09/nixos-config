-- Claude session terminals: :Claude <name> opens a named conversation in a
-- terminal buffer, resuming it when it already exists.
--
-- Names and session ids live in a registry this config owns, because Claude Code
-- tracks only the sessions currently running: a conversation nothing is hosting
-- leaves no trace outside its transcript. The registry is what keeps a stream of
-- work listable while it is dormant.

local M = {}

local function registry_path()
  return vim.fn.stdpath('state') .. '/claude-registry.json'
end

-- name -> { sessionId, cwd }
local function read_registry()
  local path = registry_path()
  if vim.fn.filereadable(path) == 0 then return {} end
  local ok, parsed = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), '\n'))
  if not ok or type(parsed) ~= 'table' then return {} end
  return parsed
end

local function write_registry(entries)
  vim.fn.writefile({ vim.json.encode(entries) }, registry_path())
end

-- Claude Code writes one file per running session, keyed by pid, carrying the
-- session's id and whether it is mid-turn. Reading them costs no subprocess,
-- unlike `claude agents --json`.
local function live_by_session_id()
  local live = {}
  for _, path in ipairs(vim.fn.glob(vim.fn.expand('~/.claude/sessions') .. '/*.json', false, true)) do
    local ok, lines = pcall(vim.fn.readfile, path)
    if ok then
      local parsed_ok, s = pcall(vim.json.decode, table.concat(lines, '\n'))
      if parsed_ok and type(s) == 'table' and s.sessionId then live[s.sessionId] = s end
    end
  end
  return live
end

-- Registry order is undefined, so rows sort by name to keep the sidebar stable
-- between renders.
function M.rows()
  local live = live_by_session_id()
  local rows = {}
  for name, entry in pairs(read_registry()) do
    local s = live[entry.sessionId]
    table.insert(rows, {
      name = name,
      sessionId = entry.sessionId,
      cwd = entry.cwd,
      live = s ~= nil,
      status = s and s.status or nil,
    })
  end
  table.sort(rows, function(a, b) return a.name < b.name end)
  return rows
end

-- A conversation's transcript is stored under the directory it started in, so a
-- resume runs from the recorded cwd rather than wherever the editor happens to be.
local function open_cmd(name)
  local entries = read_registry()
  local entry = entries[name]

  if entry then
    return 'cd ' .. vim.fn.shellescape(entry.cwd)
      .. ' && claude --resume ' .. entry.sessionId
  end

  local id = vim.fn.readfile('/proc/sys/kernel/random/uuid')[1]
  entries[name] = { sessionId = id, cwd = vim.fn.getcwd() }
  write_registry(entries)
  return 'claude --session-id ' .. id .. ' -n ' .. vim.fn.shellescape(name)
end

local function complete(arg_lead)
  local names = {}
  for _, row in ipairs(M.rows()) do
    if row.name:find(arg_lead, 1, true) == 1 then table.insert(names, row.name) end
  end
  return names
end

vim.api.nvim_create_user_command('Claude', function(opts)
  local name = opts.args
  local prev = vim.api.nvim_get_current_buf()
  vim.cmd('terminal ' .. open_cmd(name))
  local old_name = vim.api.nvim_buf_get_name(0)
  vim.api.nvim_buf_set_name(0, 'claude:' .. name)
  -- nvim_buf_set_name leaves a phantom buffer with the old term:// name; wipe it
  local phantom = vim.fn.bufnr(old_name)
  if phantom ~= -1 and phantom ~= vim.api.nvim_get_current_buf() then
    vim.api.nvim_buf_delete(phantom, { force = true })
  end
  -- Restore alternate buffer so <C-^> returns to the buffer we came from
  if prev ~= -1 and vim.api.nvim_buf_is_valid(prev) then
    local cur = vim.api.nvim_get_current_buf()
    vim.api.nvim_set_current_buf(prev)
    vim.api.nvim_set_current_buf(cur)
  end
end, { nargs = 1, complete = complete })

-- Drop a name from the registry and wipe its buffer. The conversation itself
-- survives on disk; `claude --resume <id>` still reaches it.
vim.api.nvim_create_user_command('ClaudeForget', function(opts)
  local name = opts.args
  local entries = read_registry()
  if not entries[name] then
    return vim.notify('no registry entry named ' .. name, vim.log.levels.WARN)
  end
  local buf = vim.fn.bufnr('claude:' .. name)
  if buf ~= -1 then vim.api.nvim_buf_delete(buf, { force = true }) end
  print('Forgot claude session: ' .. name .. ' (' .. entries[name].sessionId .. ')')
  entries[name] = nil
  write_registry(entries)
end, { nargs = 1, complete = complete })

return M
