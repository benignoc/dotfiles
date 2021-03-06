set termguicolors
filetype plugin indent on " filetype detection[ON] plugin[ON] indent[ON]

" Making sure default encoding is utf-8
set encoding=utf-8

" Setting default font
set guifont=MesloLGM\ NF

""vim: fdm=marker ts=2 sts=2 sw=2

" Check https://github.com/saaguero/dotvim/blob/master/.vimrc
" Variables {{{
let mapleader = ","
let maplocalleader = ","
" Mapping the reverse character search to another key 
noremap \ ,
let s:is_windows = has('win32') || has('win64')
let s:is_nvim = has('nvim')
"}}}

if s:is_windows
	set rtp+=~/.vim
endif

" ========== PLUGINS ==========
"call plug#begin('~/AppData/Local/nvim/plugged')
call plug#begin('~/.vim/plugged')
" below are some vim plugin for demonstration purpose 

" ---------- Utility Plugins ----------
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-unimpaired' "{{{
	" custom unimpaired-like mappings
	nnoremap coa :ALEToggle<cr>
	nnoremap cog :GitGutterToggle<cr>
	" easier mappings for navigating the quickfix list
	nnoremap <silent> <A-up> :cprevious<cr>
	nnoremap <silent> <A-down> :cnext<cr>
"}}}
" Better language packs
Plug 'sheerun/vim-polyglot'

" PlugInstall and PlugUpdate will clone fzf in ~/.fzf and run the install script
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
" Both options are optional. You don't have to install fzf in ~/.fzf
" and you don't have to run the install script if you use fzf only in Vim.

" Shorthand notation; fetches https://github.com/junegunn/vim-easy-align
Plug 'junegunn/vim-easy-align' "{{{
	" Align everything, since by default it doesn't align inside a comment
	let g:easy_align_ignore_groups = []
	let g:easy_align_delimiters = {
				\ ';': { 'pattern': ';', 'left_margin': 0, 'stick_to_left': 1 } }
	xmap gl <Plug>(LiveEasyAlign)
	nmap gl <Plug>(LiveEasyAlign)

    " Start interactive EasyAlign in visual mode (e.g. vipga)
    " Start interactive EasyAlign for a motion/text object (e.g. gaip)
    nmap ga <Plug>(EasyAlign)
"}}}

" ---------- Programming Plugins ---------- "{{{
Plug 'w0rp/ale' "{{{
	let g:ale_linters = {'spec': ['rpmlint']}
"}}}

Plug 'tpope/vim-commentary'

" Asynchronous autocompletion
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }

" Management of snippets, and snippet library
Plug 'Shougo/neosnippet.vim'
Plug 'Shougo/neosnippet-snippets'

Plug 'bfredl/nvim-ipy'

" Run Asynchronous tasks like make etc...
Plug 'skywind3000/asyncrun.vim'

" Generate HTML in a simple way
Plug 'mattn/emmet-vim'

" Class/module browser
Plug 'majutsushi/tagbar' "{{{
    " toggle tagbar display
    " map <C-m> :TagbarToggle<CR>
    map <F4> :TagbarToggle<CR>
    " autofocus on tagbar open
    let g:tagbar_autofocus = 1
    "}}}

" ---------- Markdown / Writing ----------
Plug 'godlygeek/tabular'
Plug 'plasticboy/vim-markdown' "{{{
    autocmd Filetype markdown let b:sleuth_automatic=0
    autocmd Filetype markdown set conceallevel=0
"}}}
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() } } "{{{
    let g:mkdp_markdown_css='~/dotfiles/github-markdown-css.css'
    let g:mkdp_refresh_slow=1
    "}}}
" Plug 'tyru/open-browser.vim' " For previm to open on current open browser
" Plug 'previm/previm' " Markdown Preview accepting mermaid
Plug 'junegunn/goyo.vim' "{{{
autocmd! User GoyoEnter Limelight
autocmd! User GoyoLeave Limelight! 
"}}}
Plug 'junegunn/limelight.vim' "{{{
  nmap <LocalLeader>l <Plug>(Limelight)
  xmap <LocalLeader>l <Plug>(Limelight)
"}}}

" ColorScheme and visuals Theme / Interface
Plug 'mhinz/vim-startify'
Plug 'mhartington/oceanic-next' 
Plug 'jnurmine/Zenburn'
Plug 'ajh17/Spacegray.vim' "TODO check if its nice
Plug 'w0ng/vim-hybrid' " TODO Check if its nice
Plug 'tomasr/molokai'

call plug#end() "}}}

""""""""""""""""""""""""""""""
"
" Configuration Section
"
""""""""""""""""""""""""""""""

" Toggle line numbers
set number
set ruler

" Set Proper Tabs "{{{
set tabstop=4
set shiftwidth=4
set smarttab
set expandtab

" remove ugly vertical lines on window division
set fillchars+=vert:\ 

"Proper PEP8 indentation
au BufNewFile,BufRead *.py
    \ set tabstop=4     |
    \ set softtabstop=4 |
    \ set shiftwidth=4  | "When using >> << commands, shift lines 4 spaces
    \ set textwidth=79  |
    \ set expandtab     | "Use spaces instead of tabs
    \ set autoindent    | "Indent when moving to next line
    \ set cursorline    | "Show cursor line
    \ set showmatch     | "Show matching () [] pairs
    \ set fileformat=unix

au BufNewFile,BufRead *.js, *.html, *.css
    \ set tabstop=2      |
    \ set softtabstop=2  |
    \ set shiftwidth=2
"}}}

" Set Split Preferences
set splitbelow
set splitright

set cursorline " Enable highlighting of the current line

" enable mouse in terminal
set mouse=a

" Make search case insensitive:
set hlsearch
set incsearch
set ignorecase
set smartcase

" Theme "{{{
colorscheme molokai

" enable all Python syntax highlighting features
let python_highlight_all = 1
"}}}

" netrw check https://shapeshed.com/vim-netrw
let g:netrw_list_hide= '.*\.swp$,.*\.pyc$' " Ignore .\swp in list
let g:netrw_winsize = 25 

" Enable folding
set foldmethod=indent
set foldlevel=99

" Ability to add python breakpoints
" (I use ipdb, but you can change it to whatever tool you use for debugging)
au FileType python map <silent> <leader>b Oimport ipdb; ipdb.set_trace()<esc>

" Deoplete "{{{
let g:deoplete#enable_at_startup = 1
"}}}

" Snippets "{{{
" Plugin key-mappings.
" Note: It must be "imap" and "smap".  It uses <Plug> mappings.
imap <C-k>     <Plug>(neosnippet_expand_or_jump)
smap <C-k>     <Plug>(neosnippet_expand_or_jump)
xmap <C-k>     <Plug>(neosnippet_expand_target)

" SuperTab like snippets behavior.
" Note: It must be "imap" and "smap".  It uses <Plug> mappings.
"imap <expr><TAB>
" \ pumvisible() ? "\<C-n>" :
" \ neosnippet#expandable_or_jumpable() ?
" \    "\<Plug>(neosnippet_expand_or_jump)" : "\<TAB>"
smap <expr><TAB> neosnippet#expandable_or_jumpable() ?
\ "\<Plug>(neosnippet_expand_or_jump)" : "\<TAB>"

" For conceal markers.
if has('conceal')
  set conceallevel=2 concealcursor=niv
  endif
"}}}

if s:is_windows
    let g:python3_host_prog = 'C:\Users\b.calvo\miniconda3\python.EXE'
else
    let g:python3_host_prog = '/home/bcalvo/.pyenv/shims/python'
endif

"""""""""""""""""""""""""""""""""""""
" Mappings configurationn
"""""""""""""""""""""""""""""""""""""
nnoremap <silent> [b :bprevious<CR>
nnoremap <silent> ]b :bnext<CR>
nnoremap <silent> [B :bfirst<CR>
nnoremap <silent> ]B :blast<CR> 

"Expand redraw to also hide highlighting
nnoremap <silent> <C-l> :<C-u>nohlsearch<CR><c-l>

" Launch spelling check Toggle spell checking
nnoremap <LocalLeader>s :set invspell<CR

" Map ESC to exit terminal mode
tnoremap <Esc> <C-\><C-n>
" Quickly navigate nvim panes (with alt direction) "{{{
" In TMUX same keys but with ALT 
" To use `ALT+{h,j,k,l}` to navigate windows from any mode: >
tnoremap <A-h> <C-\><C-N><C-w>h
tnoremap <A-j> <C-\><C-N><C-w>j
tnoremap <A-k> <C-\><C-N><C-w>k
tnoremap <A-l> <C-\><C-N><C-w>l
inoremap <A-h> <C-\><C-N><C-w>h
inoremap <A-j> <C-\><C-N><C-w>j
inoremap <A-k> <C-\><C-N><C-w>k
inoremap <A-l> <C-\><C-N><C-w>l
nnoremap <A-h> <C-w>h
nnoremap <A-j> <C-w>j
nnoremap <A-k> <C-w>k
nnoremap <A-l> <C-w>l
"}}}


"""""""""""""""""""""""""""""""""""""
" Status Line
"""""""""""""""""""""""""""""""""""""

function! GitBranch()
  return system("git rev-parse --abbrev-ref HEAD 2>/dev/null | tr -d '\n'")
endfunction

function! StatuslineGit()
  let l:branchname = GitBranch()
  return strlen(l:branchname) > 0?'  '.l:branchname.' ':''
endfunction

set statusline=
set statusline+=%#PmenuSel#
set statusline+=%{StatuslineGit()}
set statusline+=%#LineNr#
set statusline+=\ %f
set statusline+=%m\
set statusline+=%=
set statusline+=%#CursorColumn#
set statusline+=\ %y
set statusline+=\ %{&fileencoding?&fileencoding:&encoding}
set statusline+=\[%{&fileformat}\]
set statusline+=\ %p%%
set statusline+=\ %l:%c
set statusline+=\ 
