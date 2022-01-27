lua <<EOF
-- Ensure that packer is installed
local fn = vim.fn
local install_path = fn.stdpath("data").."/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({
        "git", "clone", "https://github.com/wbthomason/packer.nvim",
        install_path
    })
    vim.api.nvim_command "packadd packer.nvim"
end

require("plugins")
EOF

"-------- Utilities --------
" Sometimes branch names are too long
function! TruncateGitBranch()
    let len_limit=30
    " This can be any function that returns the current HEAD
    let head = FugitiveHead()
    return len(head) > len_limit ? strpart(head, 0, len_limit) . "..."
        \ : head
endfunction

lua <<EOF
-- Colorscheme
local color_term_values = {"-256color", "alacritty"}
for _, term_value in ipairs(color_term_values) do
    if vim.endswith(vim.env.TERM, term_value) then
        vim.opt.termguicolors = true
    end
end
vim.cmd("syntax on")
vim.opt.background = "dark"
vim.cmd("colorscheme gruvbox")

-- nvim-treesitter
require("nvim-treesitter.configs").setup {
    ensure_installed = {
        "javascript",
        "json",
        "latex",
        "python",
        "toml",
        "tsx",
        "typescript",
        "yaml"
    },
    highlight = {
        enable = true,
    },
}

-- lspconfig
local lspconfig = require("lspconfig")

local on_attach  = function(client, bufnr)
    local options = {
        noremap = true,
        silent = true,
    }
    vim.api.nvim_buf_set_keymap(
        bufnr, "n", "gD", "<Cmd>lua vim.lsp.buf.definition()<CR>", options
    )
    -- TODO: This is broken, not sure why
    vim.api.nvim_buf_set_keymap(
        bufnr, "n", "gS", "<Cmd>lua vim.lsp.buf.signature_help()<CR>", options
    )
end

lspconfig.jedi_language_server.setup{
    on_attach = on_attach,
    root_dir = function(fname)
        local found_path = lspconfig.util.root_pattern(
            "pyproject.toml", ".git"
        )(fname)
        return found_path or vim.fn.getcwd()
    end
}

lspconfig.rust_analyzer.setup{
    on_attach = on_attach,
}

lspconfig.tsserver.setup{
    on_attach = on_attach,
}

lspconfig.ccls.setup{
    on_attach = on_attach,
}

-- Linter Config
local nvim_lint = require("lint")

-- A \n character is written when closing stdin to flush the buffer. Since vim
-- implicitly appends a newline character to the end of the file, this causes
-- flake8 to interpret the file as having two blank lines at the end, raising a
-- W391 warning.
local pattern = '[^:]+:(%d+):(%d+):(%w+):(.+)'
local groups = { 'lnum', 'col', 'code', 'message' }
nvim_lint.linters.flake8 = {
  cmd = 'flake8',
  stdin = false,
  args = {
    '--format=%(path)s:%(row)d:%(col)d:%(code)s:%(text)s',
    '--no-show-source',
    '-',
  },
  ignore_exitcode = true,
  parser = require('lint.parser').from_pattern(pattern, groups, nil, {
    ['source'] = 'flake8',
    ['severity'] = vim.diagnostic.severity.WARN,
  }),
}
nvim_lint.linters_by_ft = {
    python = {"flake8",}
}
EOF

"-------- Editor Configuration --------
let mapleader = "\<Space>"  " Map Leader to Space

" Automatically apply changes if file changes outside of nvim
set autoread
set colorcolumn=101
set conceallevel=0
set encoding=utf8
set formatoptions+=tc
set formatoptions+=r
set guicursor=
set hidden
set laststatus=2
set mouse=a
set number relativenumber
set ruler
set scl=yes  " Show sign column
set shortmess+=c
set showmatch  " Show matching parentheses
set showtabline=2  " Show file tabs
set updatetime=100  " Reduce update time to show git diffs
set visualbell  " Turn off bell sound

" Search configuration
set incsearch
set ignorecase
set smartcase

" Tabbing
set expandtab
set shiftwidth=4
set smarttab
set softtabstop=0
set tabstop=8

" Splits that make sense
set splitbelow
set splitright

" Jump to last-edit position when opening files
if has("autocmd")
    au BufReadPost * if expand('%:p') !~# '\m/\.git/' && line("'\"") > 1
                \&& line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif

filetype plugin on

"-------- Key Mappings and Commands --------
" Map ; as :
nnoremap ; :

" Stop accidentally opening help
map <F1> <Esc>
imap <F1> <Esc>

" Save and quit shortcuts
nmap <Leader>w :w<CR>
nmap <Leader>q :q!<CR>

" Move cursor on each line for wrapped line
nnoremap j gj
nnoremap k gk

" Shortcut for updating plugins
command! PU PlugInstall | PlugUpgrade
command! PC PlugClean!
command! PUP PlugUpgrade

" Fast capitalization
inoremap <c-u> <esc>bveU<esc>Ea

" No arrow keys
nnoremap <up> <nop>
nnoremap <down> <nop>
inoremap <up> <nop>
inoremap <down> <nop>
inoremap <left> <nop>
inoremap <right> <nop>

" Left and right can switch buffers
nnoremap <left> :bp<CR>
nnoremap <right> :bn<CR>

"-------- Plugin Configuration --------
" vim-signify configs
let g:signify_sign_add='++'
let g:signify_sign_delete='--'
let g:signify_sign_delete_first_line='--'
let g:signify_sign_change='=='

lua <<EOF
-- lightline
vim.g.lightline = {
    colorscheme = "powerline",
    active = {
        left = {
            {"mode", "past"},
            {"gitbranch", "filename", "readonly", "modified"}
        },
        right = {
            {"lineinfo"},
            {"fileencoding", "filetype"},
        },
    },
    inactive = {
        left = {
            {"filename", "modified"},
        }
    },
    component_function = {
        gitbranch = "TruncateGitBranch"
    },
}

-- FZF
vim.api.nvim_set_keymap("n", "<Leader>g", "<Cmd>GFiles<CR>", {noremap = true})
vim.api.nvim_set_keymap("n", "<Leader>f", "<Cmd>Files<CR>", {noremap = true})
vim.api.nvim_set_keymap("n", "<Leader>b", "<Cmd>Buffers<CR>", {noremap = true})
vim.api.nvim_set_keymap("n", "<Leader>s", "<Cmd>Rg<CR>", {noremap = true})

-- nvim-compe
vim.o.completeopt = "menuone,noselect"

require("compe").setup {
    enabled = true,
    autocomplete = true,
    source = {
        path = true,
        buffer = true,
        nvim_lsp = true,
    },
}

local compe_t = function(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

-- Use (s-)tab to:
--- move to prev/next item in completion menuone
--- jump to prev/next snippet's placeholder
_G.tab_complete = function()
    if vim.fn.pumvisible() == 1 then
        return compe_t "<C-n>"
    else
        return compe_t "<Tab>"
  end
end
_G.s_tab_complete = function()
    if vim.fn.pumvisible() == 1 then
        return compe_t "<C-p>"
    else
        -- If <S-Tab> is not working in your terminal, change it to <C-h>
        return compe_t "<S-Tab>"
    end
end

vim.api.nvim_set_keymap("i",
    "<Tab>", "v:lua.tab_complete()", {expr = true, noremap = true})
vim.api.nvim_set_keymap("i",
    "<S-Tab>", "v:lua.s_tab_complete()", {expr = true, noremap = true})
vim.api.nvim_set_keymap("i",
    "<C-Space>", "compe#complete()", {expr = true, noremap = true})
vim.api.nvim_set_keymap("i",
    "<C-e>", "compe#close('<C-e>')", {expr = true, noremap = true})
EOF
