-- Settings
vim.g.mapleader = " "                      -- Set leader key to space

-- OSC 52 clipboard — must be set before anything touches the clipboard provider
vim.g.clipboard = {
  name = 'OSC 52',
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
    ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
  },
  paste = {
    ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
    ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
  },
}

vim.opt.number = true
vim.opt.encoding = "utf-8"
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.colorcolumn = "100"                -- Marker at 100 col width
vim.opt.updatetime = 200                   -- Decrease update time to make vim gutter update faster
vim.opt.foldenable = false                 -- Don't fold by default

vim.opt.spell = false                      -- Enable built-in spell-checker
vim.cmd [[au TermOpen * setlocal nospell]] -- Disable spell-checker in terminal mode

-- Jump to bottom of terminal buffers on WinLeave so they follow new output
-- while you're in another window (Neovim exits terminal mode on WinLeave,
-- and in normal mode the viewport only follows if the cursor is at the end)
vim.api.nvim_create_autocmd('WinLeave', {
  callback = function()
    if vim.bo.buftype == 'terminal' then vim.cmd('normal! G') end
  end,
})

-- Telescope setup
local builtins = require('telescope.builtin')
local actions = require("telescope.actions")
vim.keymap.set('n', '<leader>p', builtins.find_files, {})
vim.keymap.set('n', '<leader>g', builtins.live_grep, {})
vim.keymap.set('n', '<leader>b', builtins.buffers, {})
vim.keymap.set('n', '<leader>h', builtins.help_tags, {})
vim.keymap.set('n', '<leader>s', builtins.lsp_dynamic_workspace_symbols, {})
vim.keymap.set('n', '<leader>y', builtins.lsp_document_symbols, {})
vim.keymap.set('n', '<leader>ic', builtins.lsp_incoming_calls, {})
vim.keymap.set('n', '<leader>oc', builtins.lsp_outgoing_calls, {})
vim.keymap.set('n', 'gr', builtins.lsp_references, {})
vim.keymap.set('n', 'gi', builtins.lsp_implementations, {})
require('telescope').setup {
  defaults = {
    mappings = {
      n = {
        ["q"] = actions.delete_buffer,
      },
    },
  },
}
require('telescope').load_extension('fzf')

-- Newline in normal mode
vim.keymap.set('n', '<Leader>o', 'o<Esc>')
vim.keymap.set('n', '<Leader>O', 'O<Esc>')

vim.keymap.set('n', '<leader>q', ':bp<bar>sp<bar>bn<bar>bd!<CR>') -- Wipe buffer without closing window

-- Move around windows
vim.keymap.set('n', '<M-l>', '<c-w>l')
vim.keymap.set('n', '<M-k>', '<c-w>k')
vim.keymap.set('n', '<M-j>', '<c-w>j')
vim.keymap.set('n', '<M-h>', '<c-w>h')

vim.keymap.set('n', 'cq', ':cclose<cr>', { noremap = true }) -- Close quickfix list

vim.keymap.set('t', '<C-v>', '<c-\\><c-n>pa')                -- Paste in terminal mode

-- Move around windows in terminal mode
vim.keymap.set('t', '<M-l>', '<c-\\><c-n><c-w>l')
vim.keymap.set('t', '<M-k>', '<c-\\><c-n><c-w>k')
vim.keymap.set('t', '<M-j>', '<c-\\><c-n><c-w>j')
vim.keymap.set('t', '<M-h>', '<c-\\><c-n><c-w>h')

vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>') -- Double-Esc to exit terminal mode (single Esc passes through to TUI apps)

vim.o.termguicolors = true                  -- Enable true colors

-- Working with tabs
vim.keymap.set('n', '<M-]>', ':tabnext<CR>')
vim.keymap.set('n', '<M-[>', ':tabprevious<CR>')
vim.keymap.set('t', '<M-]>', '<c-\\><c-n>:tabnext<CR>')
vim.keymap.set('t', '<M-[>', '<c-\\><c-n>:tabprevious<CR>')

-- Enable saving Taboo tab names to Session.vim
vim.o.sessionoptions = vim.o.sessionoptions .. ",tabpages,globals"

-- Mute search highlighting
vim.keymap.set('n', '<C-l>', ':<C-u>nohlsearch<CR><C-l>')

-- Toggle line wrapping
vim.keymap.set('n', '<leader>w', ':set wrap!<CR>', { noremap = true, silent = true })

-- Terminal buffer picker — custom picker because telescope's builtin buffers()
-- doesn't support filtering by buftype. Collects all terminal buffers and
-- strips the cwd prefix so named buffers display as "term:foo" / "tmux:bar".
vim.keymap.set('n', '<leader>tt', function()
  local results = {}
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[b].buftype == 'terminal' then
      table.insert(results, { bufnr = b, name = vim.api.nvim_buf_get_name(b) })
    end
  end
  if #results == 0 then return print('No terminal buffers') end
  require('telescope.pickers').new({}, {
    prompt_title = 'Terminal Buffers',
    finder = require('telescope.finders').new_table {
      results = results,
      entry_maker = function(e)
        -- nvim_buf_set_name resolves relative names against cwd; strip that prefix
        local display = e.name:gsub('^' .. vim.pesc(vim.uv.cwd() .. '/'), '')
        return { value = e.bufnr, display = display, ordinal = display, bufnr = e.bufnr }
      end,
    },
    sorter = require('telescope.config').values.generic_sorter({}),
  }):find()
end, { desc = 'Terminal buffers' })

-- Named terminal: :Term server, :Term tests, etc.
vim.api.nvim_create_user_command('Term', function(opts)
  local prev = vim.api.nvim_get_current_buf()
  vim.cmd('terminal')
  local old_name = vim.api.nvim_buf_get_name(0)
  vim.api.nvim_buf_set_name(0, 'term:' .. opts.args)
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
end, { nargs = 1 })

-- Tmux terminal: :Tmux session — attaches or creates, names buffer tmux:<session>
vim.api.nvim_create_user_command('Tmux', function(opts)
  local session = opts.args
  local prev = vim.api.nvim_get_current_buf()
  vim.cmd('terminal tmux new-session -A -s ' .. vim.fn.shellescape(session))
  local old_name = vim.api.nvim_buf_get_name(0)
  vim.api.nvim_buf_set_name(0, 'tmux:' .. session)
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
end, {
  nargs = 1,
  complete = function(arg_lead)
    local out = vim.fn.system('tmux list-sessions -F "#S" 2>/dev/null')
    local sessions = vim.split(out, '\n', { trimempty = true })
    return vim.tbl_filter(function(s) return s:find(arg_lead, 1, true) == 1 end, sessions)
  end,
})

-- Kill a tmux session and wipe its neovim buffer if one exists
vim.api.nvim_create_user_command('TmuxKill', function(opts)
  local session = opts.args
  local buf = vim.fn.bufnr('tmux:' .. session)
  if buf ~= -1 then vim.api.nvim_buf_delete(buf, { force = true }) end
  vim.fn.system('tmux kill-session -t ' .. vim.fn.shellescape(session))
  print('Killed tmux session: ' .. session)
end, {
  nargs = 1,
  complete = function(arg_lead)
    local out = vim.fn.system('tmux list-sessions -F "#S" 2>/dev/null')
    local sessions = vim.split(out, '\n', { trimempty = true })
    return vim.tbl_filter(function(s) return s:find(arg_lead, 1, true) == 1 end, sessions)
  end,
})

-- Tmux session picker — lists all tmux sessions, reuses an existing buffer if
-- one is already attached, otherwise creates a new one via :Tmux.
-- <CR> to attach, <C-d> to kill session.
-- NOTE: relies on :Tmux naming buffers "tmux:<session>"; keep in sync.
vim.keymap.set('n', '<leader>tm', function()
  local out = vim.fn.system('tmux list-sessions -F "#S" 2>/dev/null')
  local sessions = vim.split(out, '\n', { trimempty = true })
  if #sessions == 0 then return print('No tmux sessions') end
  require('telescope.pickers').new({}, {
    prompt_title = 'Tmux Sessions (C-d to kill)',
    finder = require('telescope.finders').new_table { results = sessions },
    sorter = require('telescope.config').values.generic_sorter({}),
    attach_mappings = function(_, map)
      local actions = require('telescope.actions')
      local action_state = require('telescope.actions.state')
      actions.select_default:replace(function(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        local existing = vim.fn.bufnr('tmux:' .. selection[1])
        if existing ~= -1 then
          vim.cmd('buffer ' .. existing)
        else
          vim.cmd('Tmux ' .. selection[1])
        end
      end)
      map({ 'i', 'n' }, '<C-d>', function(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if not selection then return end
        vim.cmd('TmuxKill ' .. selection[1])
        -- Refresh the picker
        local current_picker = action_state.get_current_picker(prompt_bufnr)
        local refreshed = vim.split(vim.fn.system('tmux list-sessions -F "#S" 2>/dev/null'), '\n', { trimempty = true })
        if #refreshed == 0 then return actions.close(prompt_bufnr) end
        current_picker:refresh(require('telescope.finders').new_table { results = refreshed })
      end)
      return true
    end,
  }):find()
end, { desc = 'Tmux session picker' })

-- Tmux session sidebar — a read-only listing of tmux sessions in a left split,
-- with the session showing in the focused window highlighted. Shares the left
-- split with NERDTree: opening either closes the other, so only one sidebar
-- occupies the column at a time.
local tmux_sidebar_win = nil
local tmux_sidebar_timer = nil
-- Session name per displayed line, so <CR> never has to parse the rendered text
-- and names containing spaces still resolve.
local tmux_sidebar_names = {}

-- The session list is cached because reading it costs a subprocess (~6ms), far
-- more than a frame of animation is worth paying for ten times a second.
local tmux_sidebar_sessions = {}

local function tmux_sidebar_reload()
  tmux_sidebar_sessions =
    vim.fn.systemlist([[tmux list-sessions -F '#{session_name}' 2>/dev/null]])
end

-- Spinner frames for a session mid-turn. Idle sessions get blank padding of the
-- same display width so names stay in one column.
local tmux_spinner = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }
local tmux_spinner_frame = 1

local function tmux_sidebar_lines(busy)
  tmux_sidebar_names = {}
  if #tmux_sidebar_sessions == 0 then return { '  no tmux sessions' } end
  local lines = {}
  for i, name in ipairs(tmux_sidebar_sessions) do
    local icon = busy[name] and tmux_spinner[tmux_spinner_frame] or ' '
    lines[i] = icon .. ' ' .. name
    tmux_sidebar_names[i] = name
  end
  return lines
end

local tmux_sidebar_ns = vim.api.nvim_create_namespace('tmux_sidebar')
-- Custom group, so no colorscheme defines it and the link survives a change of
-- theme while resolving to that theme's Visual.
vim.api.nvim_set_hl(0, 'TmuxSidebarActive', { link = 'Visual', default = true })

-- Sessions whose Claude is mid-turn. claude-session-state.sh writes a marker per
-- tmux session when a turn starts and removes it when the turn ends.
--
-- A marker can outlive the turn: interrupting mid-turn skips the end-of-turn hook.
-- The cutoff is deliberately generous because a turn can think for a long time
-- without touching a tool, and clearing a live session's marker early would be the
-- worse error. Markers for sessions that no longer exist cost nothing, since only
-- sessions tmux still lists are ever drawn.
local tmux_busy_max_age = 30 * 60

local function tmux_busy_sessions()
  local dir = (vim.env.XDG_CACHE_HOME or (vim.env.HOME .. '/.cache')) .. '/claude-busy'
  local busy = {}
  local ok, iter = pcall(vim.fs.dir, dir)
  if not ok then return busy end
  local now = os.time()
  for name, kind in iter do
    if kind == 'file' then
      local st = vim.uv.fs_stat(dir .. '/' .. name)
      if st and now - st.mtime.sec < tmux_busy_max_age then busy[name] = true end
    end
  end
  return busy
end

-- The session showing in the focused window, or in the window focused before the
-- sidebar when the sidebar holds focus. Buffer names resolve against cwd, so the
-- `tmux:` prefix sits after the last path separator.
local function tmux_sidebar_active_name()
  local win = vim.api.nvim_get_current_win()
  if win == tmux_sidebar_win then win = vim.fn.win_getid(vim.fn.winnr('#')) end
  if win == 0 or not vim.api.nvim_win_is_valid(win) then return nil end
  local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
  return bufname:match('tmux:(.+)$')
end

local function tmux_sidebar_render()
  if not (tmux_sidebar_win and vim.api.nvim_win_is_valid(tmux_sidebar_win)) then return end
  local buf = vim.api.nvim_win_get_buf(tmux_sidebar_win)
  local busy = tmux_busy_sessions()
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, tmux_sidebar_lines(busy))
  vim.bo[buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(buf, tmux_sidebar_ns, 0, -1)
  local active = tmux_sidebar_active_name()
  for i, name in ipairs(tmux_sidebar_names) do
    if name == active then
      vim.api.nvim_buf_set_extmark(buf, tmux_sidebar_ns, i - 1, 0,
        { line_hl_group = 'TmuxSidebarActive' })
    end
  end
end

-- Open the session under the cursor in the window used before the sidebar, so
-- the sidebar survives. Reuses an existing :Tmux buffer rather than reattaching.
local function tmux_sidebar_open_session()
  local name = tmux_sidebar_names[vim.fn.line('.')]
  if not name then return end
  local prev = vim.fn.win_getid(vim.fn.winnr('#'))
  if prev ~= 0 and prev ~= tmux_sidebar_win and vim.api.nvim_win_is_valid(prev) then
    vim.api.nvim_set_current_win(prev)
  else
    -- Sidebar is the only window; make one beside it and keep its width.
    vim.cmd('rightbelow vsplit')
    if tmux_sidebar_win and vim.api.nvim_win_is_valid(tmux_sidebar_win) then
      vim.api.nvim_win_set_width(tmux_sidebar_win, 32)
    end
  end
  local existing = vim.fn.bufnr('tmux:' .. name)
  if existing ~= -1 then
    vim.cmd('buffer ' .. existing)
  else
    vim.cmd('Tmux ' .. name)
  end
  -- Deferred: :Tmux renames the buffer and swaps the alternate after the events
  -- a render would ride on, so re-read once that has settled.
  vim.schedule(tmux_sidebar_render)
end

-- Kill the session under the cursor. :TmuxKill also wipes its buffer.
local function tmux_sidebar_kill_session()
  local name = tmux_sidebar_names[vim.fn.line('.')]
  if not name then return end
  vim.cmd('TmuxKill ' .. name)
  tmux_sidebar_render()
end

local function tmux_sidebar_close()
  if tmux_sidebar_timer then
    tmux_sidebar_timer:stop()
    tmux_sidebar_timer:close()
    tmux_sidebar_timer = nil
  end
  if tmux_sidebar_win and vim.api.nvim_win_is_valid(tmux_sidebar_win) then
    vim.api.nvim_win_close(tmux_sidebar_win, true)
  end
  tmux_sidebar_win = nil
end

local function tmux_sidebar_open()
  vim.cmd('NERDTreeClose') -- no-op when closed; keeps one sidebar in the column
  vim.cmd('topleft vsplit')
  tmux_sidebar_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_width(tmux_sidebar_win, 32)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(tmux_sidebar_win, buf)
  vim.bo[buf].filetype = 'tmuxsessions'
  vim.bo[buf].buftype = 'nofile'
  vim.wo[tmux_sidebar_win].number = false
  vim.wo[tmux_sidebar_win].relativenumber = false
  vim.wo[tmux_sidebar_win].wrap = false
  vim.wo[tmux_sidebar_win].winfixwidth = true
  vim.keymap.set('n', 'q', tmux_sidebar_close, { buffer = buf, nowait = true })
  vim.keymap.set('n', '<CR>', tmux_sidebar_open_session, { buffer = buf, nowait = true })
  vim.keymap.set('n', '<C-d>', tmux_sidebar_kill_session, { buffer = buf, nowait = true })
  tmux_sidebar_reload() -- the cache is empty until the first tick would fill it
  tmux_sidebar_render()
  -- Busy state changes while you sit in one window, where no autocmd fires, and a
  -- spinner needs a frame roughly every 100ms. Only the session list is expensive,
  -- so it is re-read once a second rather than every frame. Runs only while the
  -- sidebar is up, and stops itself if the window goes away by some route other
  -- than tmux_sidebar_close, such as :q or closing the tab.
  local tick = 0
  tmux_sidebar_timer = vim.uv.new_timer()
  tmux_sidebar_timer:start(100, 100, function()
    vim.schedule(function()
      if not (tmux_sidebar_win and vim.api.nvim_win_is_valid(tmux_sidebar_win)) then
        return tmux_sidebar_close()
      end
      tick = tick + 1
      tmux_spinner_frame = tmux_spinner_frame % #tmux_spinner + 1
      if tick % 10 == 0 then tmux_sidebar_reload() end
      tmux_sidebar_render()
    end)
  end)
end

vim.keymap.set('n', '<leader>ts', function()
  if tmux_sidebar_win and vim.api.nvim_win_is_valid(tmux_sidebar_win) then
    tmux_sidebar_close()
  else
    tmux_sidebar_open()
  end
end, { desc = 'Toggle tmux session sidebar' })

-- tmux state changes outside nvim, so re-read on the events that mean "back here".
-- BufEnter also keeps the active-session highlight current when a window's buffer
-- changes without the window itself changing.
vim.api.nvim_create_autocmd({ 'FocusGained', 'WinEnter', 'BufEnter' },
  { callback = tmux_sidebar_render })

-- NERDTree takes the same column, so close the sidebar when it opens
vim.keymap.set('n', '<leader>nt', function()
  tmux_sidebar_close()
  vim.cmd('NERDTreeToggle')
end, { noremap = true, silent = true, desc = 'Toggle NERDTree' })

-- vim-test
vim.cmd([[let test#strategy = "neovim"]])
vim.keymap.set('n', '<leader>t', ':TestNearest<CR>')
vim.keymap.set('n', '<leader>T', ':TestFile<CR>')
vim.keymap.set('n', '<leader>l', ':TestLast<CR>')

vim.cmd([[
" Set nvim as preferred editor for Git
if has('nvim') && executable('nvr')
	let $VISUAL="nvr -cc split --remote-wait +'set bufhidden=wipe'"
endif

" Colorscheme
let g:sonokai_style = 'andromeda'
let g:sonokai_better_performance = 1
silent! colorscheme sonokai

" Prevent nesting of neovim instances
if has('nvim') && executable('nvr')
  let $VISUAL="nvr -cc split --remote-wait +'set bufhidden=wipe'"
endif
]])

-- 'q' to quit quickfix
vim.api.nvim_create_autocmd(
  "FileType",
  { pattern = { "qf" }, command = [[nnoremap <buffer><silent> q :close<CR>]] }
)

-- Check if file exists
function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

-- get all lines from a file, returns an empty
-- list/table if the file does not exist
function lines_from(file)
  if not file_exists(file) then return {} end
  local lines = {}
  for line in io.lines(file) do
    lines[#lines + 1] = line
  end
  return lines
end

-- Add Go header
function add_go_header(t)
  file = [[/home/amoghr/.config/nvim/headers/header.go]]
  local lines = lines_from(file)
  vim.api.nvim_buf_set_lines(t.buf, 0, 1, false, lines)
end

vim.api.nvim_create_autocmd("BufNewFile", {
  pattern = "*.go",
  callback = add_go_header,
})

require('lsp') -- Setup LSP

-- Treesitter — enable highlighting for all buffers with a parser
vim.api.nvim_create_autocmd('FileType', {
  callback = function() pcall(vim.treesitter.start) end,
})

vim.keymap.set('n', '<leader>nf', ':NERDTreeFind<CR>', { noremap = true, silent = true })

-- Set up FZF
vim.env.FZF_DEFAULT_COMMAND = 'rg --files --ignore-file .rgignore'

-- Set sh file type based on shebang.
function CheckAndSetFileType()
  -- Get the first line of the buffer
  local first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]

  -- Check if the first line matches the shebang pattern
  if first_line and first_line:match("^#!.*/bin/bash") then
    -- Set file type to sh
    vim.api.nvim_buf_set_option(0, 'filetype', 'sh')
  end
end

-- Call the function when the buffer is opened
vim.api.nvim_command('autocmd BufReadPost * lua CheckAndSetFileType()')

-- qchat-nvim
vim.keymap.set('n', '<leader>qo', ':QChatOpen<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>qc', '<cmd>QChatClose<CR>', { noremap = true, silent = true })

-- Yank current file's relative path
vim.keymap.set('n', '<leader>yf', function()
  local filepath = vim.fn.expand('%:.')
  if filepath == '' then
    print('No file path to yank')
    return
  end
  vim.fn.setreg('"', filepath)
  print('Yanked file path: ' .. filepath)
end, { noremap = true, silent = false, desc = 'Yank current file relative path' })

-- Yank text inside () to system clipboard
vim.keymap.set('n', '<leader>yl', '"+yi)', { desc = 'Yank inside () to clipboard' })

-- Smooth scrolling
require('neoscroll').setup()

-- Set default colorscheme
vim.cmd('colorscheme rose-pine')



-- Treesitter text objects for better navigation
require('nvim-treesitter-textobjects').setup({
  move = {
    enable = true,
    set_jumps = true,
    goto_next_start = {
      [']f'] = '@function.outer',
    },
    goto_previous_start = {
      ['[f'] = '@function.outer',
    },
  },
})

-- Diffview — changeset review. The working-tree side is a real buffer, so LSP
-- and treesitter navigation work inside the diff; the indexed/rev side does not.
require('diffview').setup({
  use_icons = false, -- nvim-web-devicons isn't installed
  enhanced_diff_hl = true,
  view = {
    merge_tool = { layout = 'diff3_mixed' },
  },
  keymaps = {
    view = { { 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close diffview' } } },
    file_panel = { { 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close diffview' } } },
    file_history_panel = { { 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close diffview' } } },
  },
})

vim.keymap.set('n', '<leader>dd', ':DiffviewOpen<CR>', { desc = 'Review working tree vs HEAD' })
vim.keymap.set('n', '<leader>dc', ':DiffviewClose<CR>', { desc = 'Close diffview' })
vim.keymap.set('n', '<leader>dh', ':DiffviewFileHistory %<CR>', { desc = 'History of current file' })
vim.keymap.set('n', '<leader>dH', ':DiffviewFileHistory<CR>', { desc = 'History of current branch' })
-- Review a whole branch: diff against the merge-base so only this branch's work shows
vim.keymap.set('n', '<leader>db', function()
  local base = vim.fn.systemlist('git merge-base HEAD origin/HEAD 2>/dev/null')[1]
  if not base or base == '' then return print('No merge-base with origin/HEAD') end
  vim.cmd('DiffviewOpen ' .. base)
end, { desc = 'Review branch vs merge-base' })

-- Modern statusline
require('lualine').setup({
  options = {
    theme = 'rose-pine'
  }
})

-- Disco mode - cycle through colorschemes
local schemes = {'sonokai', 'gruvbox', 'nord', 'dracula', 'onedark', 'tokyonight', 'catppuccin', 'kanagawa', 'rose-pine', 'nightfox'}
local current = 1
vim.keymap.set('n', '<leader>cs', function()
  current = current % #schemes + 1
  pcall(vim.cmd, 'colorscheme ' .. schemes[current])
  require('lualine').setup({
    options = {
      theme = schemes[current]
    }
  })
  print('🎨 ' .. schemes[current])
end)
