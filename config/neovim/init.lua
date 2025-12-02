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

-- Treesitter
require('nvim-treesitter.configs').setup {
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
}

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
require('nvim-treesitter.configs').setup({
  textobjects = {
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
