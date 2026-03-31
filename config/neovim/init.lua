-- Settings
vim.g.mapleader = " "                      -- Set leader key to space
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

vim.keymap.set('t', '<Esc>', '<C-\\><C-n>') -- Esc to get out of terminal mode

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
  vim.cmd('terminal')
  local old_name = vim.api.nvim_buf_get_name(0)
  vim.api.nvim_buf_set_name(0, 'term:' .. opts.args)
  -- nvim_buf_set_name leaves a phantom buffer with the old term:// name; wipe it
  local phantom = vim.fn.bufnr(old_name)
  if phantom ~= -1 and phantom ~= vim.api.nvim_get_current_buf() then
    vim.api.nvim_buf_delete(phantom, { force = true })
  end
end, { nargs = 1 })

-- Tmux terminal: :Tmux session — attaches or creates, names buffer tmux:<session>
vim.api.nvim_create_user_command('Tmux', function(opts)
  local session = opts.args
  vim.cmd('terminal tmux new-session -A -s ' .. vim.fn.shellescape(session))
  local old_name = vim.api.nvim_buf_get_name(0)
  vim.api.nvim_buf_set_name(0, 'tmux:' .. session)
  -- nvim_buf_set_name leaves a phantom buffer with the old term:// name; wipe it
  local phantom = vim.fn.bufnr(old_name)
  if phantom ~= -1 and phantom ~= vim.api.nvim_get_current_buf() then
    vim.api.nvim_buf_delete(phantom, { force = true })
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

-- Treesitter (highlight enabled by default in new nvim-treesitter)
vim.treesitter.start = vim.treesitter.start or function() end

-- Render markdown inline
require('render-markdown').setup({})

-- NERDTree toggle
vim.keymap.set('n', '<leader>nt', ':NERDTreeToggle<CR>', { noremap = true, silent = true })
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
