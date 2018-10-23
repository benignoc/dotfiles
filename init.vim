" Benigno Calvo Neovim Configuration

" ----- Generic Settings ------
let mapleader = ","
let mapLocalLeader = ","
set termguicolors
filetype plugin indent on " filetype detection[ON] plugin[ON] indent[ON]

" Making sure default encoding is utf-8
set encoding=utf-8
" syntax on
set nocompatible
" Setting default font
"set guifont=DejaVu\ Sans:s12
set guifont=DejaVu\ Sans\ Mono\ for\ Powerline
" set guifont=Inconsolata
" set guifont=Inconsolata\ for\ Powerline:s12


" Setup Vim-Plug ------------------------------------------------{{{
" Specify a directory for plugins
" - For Neovim: ~/.local/share/nvim/plugged
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.local/share/nvim/plugged')


" Utility
Plug 'scrooloose/nerdtree'
Plug 'majutsushi/tagbar'
Plug 'junegunn/vim-easy-align'
Plug 'jiangmiao/auto-pairs' "Closing parenthesis etc
Plug 'tpope/vim-fugitive' " Use for git commands while in Vim
Plug 'tpope/vim-surround'
" Plug 'powerline/powerline', {'rtp': 'powerline/bindings/vim/'} "Using airline


" Generic Programming Support
Plug 'cjrh/vim-conda' " to use :CondaChangeEnv<ENTER> adapt to Conda env
Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets'
if has('nvim') " Deoplete is needed to use deoplete-jedi
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
else
  Plug 'Shougo/deoplete.nvim'
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc'
endif
" TODO Check if happier with neocomplete
Plug 'zchee/deoplete-jedi' " Autocompletion for Python
Plug 'w0rp/ale'  "Asynchronous syntax check (ala syntastic)
Plug 'skywind3000/asyncrun.vim' "Run Asynchronous tasks like make etc...
" Plug 'neomake/neomake' " Asynchronous make for neovim TODO check if useful
" Plug 'Vigemus/iron.nvim' ", {'do': ':UpdateRemotePlugins'}
" Plug 'Vigemus/iron.nvim', { 'branch': 'lua/replace' }
" Plug 'ivanov/vim-ipython' " Only working with python2
" Plug 'broesler/jupyter-vim' " For some reason they give error
" Plug 'wmvanvliet/jupyter-vim'
Plug 'bfredl/nvim-ipy'
Plug 'tpope/vim-commentary'
Plug 'KabbAmine/zeavim.vim'  "Integration with Zeal <leader>z


" Integration with TMUX
"Plug 'benmills/vimux' 
"Plug 'julienr/vim-cellmode'
"Plug 'jgors/vimux-ipy'

" Python
Plug 'google/yapf'

" Markdown / Writing
Plug 'godlygeek/tabular'
" Plug 'plasticboy/vim-markdown'
Plug 'gabrielelana/vim-markdown'
" Plug 'dpelle/vim-LanguageTool' " Check grammar several languages TODO install java tool
Plug 'reedes/vim-pencil' " TODO check if useful for writing

" ColorScheme and visuals Theme / Interface
Plug 'mhartington/oceanic-next'
Plug 'altercation/vim-colors-solarized'
Plug 'vim-airline/vim-airline' " Barra de estado de vim
Plug 'vim-airline/vim-airline-themes'  " Temas para airline
Plug 'jnurmine/Zenburn'
Plug 'junegunn/goyo.vim'
Plug 'junegunn/limelight.vim'
Plug 'ajh17/Spacegray.vim' "TODO check if its nice
Plug 'w0ng/vim-hybrid' " TODO Check if its nice



" PlugInstall and PlugUpdate will clone fzf in ~/.fzf and run install script
" Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
  " Both options are optional. You don't have to install fzf in ~/.fzf
  " and you don't have to run install script if you use fzf only in Vim.

" Initialize plugin system
call plug#end()
" END VIM-PLUG   ---------------------------------- }}}


"""""""""""""""""""""""""""""""""""""
" 
" Configuration Section
"
"""""""""""""""""""""""""""""""""""""

" Toggle line numbers
set number
set ruler

" Set Proper Tabs
set tabstop=4
set shiftwidth=4
set smarttab
set expandtab

" Set Split preferences
set splitbelow
set splitright

set laststatus=2 " Always display the status line
set cursorline " Enable highlighting of the current line

" Enable mouse in terminal
set mouse=a

" Easier formatting of paragraphs
" vmap Q gq
" nmap Q gqap

" Make search case insensitive:
set hlsearch
set incsearch
set ignorecase
set smartcase

" To allow yank to copy to normal clipboard
set clipboard=unnamed


" Display Configuration ------------------------
if (has("termguicolors"))
 set termguicolors
endif
" Theme
colorscheme OceanicNext
" colorscheme solarized
" colorscheme spacegray " TODO Check these settings for spacegray
let g:spacegray_underline_search = 1
let g:spacegray_italicize_comments = 1
let g:hybrid_custom_term_colors = 1 " TODO Check these settings for hybrid
let g:hybrid_reduced_contrast = 1 
set background=dark
syntax enable
" to enter limelight and exist limelight upon entering or exiting Goyo
autocmd! User GoyoEnter Limelight
autocmd! User GoyoLeave Limelight!


" Vim-Airline Configuration
let g:airline#extensions#tabline#enabled = 1 " Mostrar buffers abiertos (como pestañas)
let g:airline#extensions#tabline#fnamemod = ':t'  " Mostrar sólo el nombre del archivo
" let g:airline_theme='hybrid'
set noshowmode  " No mostrar el modo actual (ya lo muestra la barra de estado)
" air-line
let g:airline_powerline_fonts = 1 " Cargar fuente Powerline y símbolos (ver nota)
if !exists('g:airline_symbols')
    let g:airline_symbols = {}
endif
" unicode symbols
let g:airline_left_sep = '»'
let g:airline_left_sep = '▶'
let g:airline_right_sep = '«'
let g:airline_right_sep = '◀'
let g:airline_symbols.linenr = '␊'
let g:airline_symbols.linenr = '␤'
let g:airline_symbols.linenr = '¶'
let g:airline_symbols.branch = '⎇'
let g:airline_symbols.paste = 'ρ'
let g:airline_symbols.paste = 'Þ'
let g:airline_symbols.paste = '∥'
let g:airline_symbols.whitespace = 'Ξ'

" airline symbols
let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''
let g:airline_symbols.branch = ''
let g:airline_symbols.readonly = ''
let g:airline_symbols.linenr = ''

" Github Issues Configuration
" let g:github_access_token = "e6fb845bd306a3ca7f... " TODO fill in


" Settings for Writting
" let g:languagetool_jar  = '/.../languagetool-commandline.jar' " TODO

" Vim-pencil Configuration " TODO when install pencil
let g:pencil#wrapModeDefault = 'soft'   " default is 'hard'
augroup pencil
  autocmd!
  autocmd FileType markdown,mkd call pencil#init()
  autocmd FileType text         call pencil#init()
augroup END


" Vim-Test Configuration "TODO Check 
" let test#strategy = 'vimux'


" netrw check https://shapeshed.com/vim-netrw/
" let g:netrw_liststyle = 3
" use gh to toggle view of hidden files.
" let g:netrw_banner = 0
let g:netrw_list_hide= '.*\.swp$,.*\.pyc$' " Ignore .\swp in list
let g:netrw_winsize = 25

let g:deoplete#enable_at_startup = 1
"
" asyncrun option for opening quickfix automatically
let g:asyncrun_open = 15
"
" Configuración de fzf (fuzzy search)
" Ejecutar comandos con alt-enter :Commands
" let g:fzf_commands_expect = 'alt-enter'
" Guardar historial de búsquedas
" let g:fzf_history_dir = '~/.local/share/fzf-history'
" Empezar a buscar presionando Ctrl + p
" nnoremap <C-p> :Files<CR>


" Enable folding
set foldmethod=indent
set foldlevel=99

" LanguageTool (Grammar checking)
" let g:languagetool_jar='$HOME/LanguageTool-4.2/languagetool-commandline.jar'
"
" To avoid some errors using CondachangEnv
" let g:jedi#force_py_version = 2
" let g:UltisnipsUsePythonVersion = 2
"
" Snippets handling
" Trigger configuration. Do not use <tab> if you use https://github.com/Valloric/YouCompleteMe.
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"
" If you want :UltiSnipsEdit to split your window.
let g:UltiSnipsEditSplit="vertical"

let NERDTreeIgnore=['\.pyc$', '\~$'] "ignore files in NERDTree

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

" enable all Python syntax highlighting features
let python_highlight_all = 1

" So that <tab> Completion in Ultisnippets works need to turn this off:
" gabrielelana/vim-markdown
let g:markdown_enable_insert_mode_mappings = 0
" Enable folding in markdown
let g:markdown_enable_folding = 1

" FZF: This is the default extra key bindings
" let g:fzf_action = {
"   \ 'ctrl-t': 'tab split',
"   \ 'ctrl-x': 'split',
"   \ 'ctrl-v': 'vsplit' }

" Automatic reloading of init.vim
" autocmd! bufwritepost .init.vim source %

" Specific settings for WINDOWS 
" adjust configuration for such hostile environment as Windows {{{
if has("win32") || has("win16")
  lang C
  " TODO Check iskeyword setting
  " set iskeyword=48-57,65-90,97-122,_,161,163,166,172,177,179,182,188,191,198,202,209,211,230,234,241,243,143,156,159,165,175,185
  cd C:\Users\benig\
  let g:python3_host_prog='C:\tools\miniconda3\python'
  let g:python_host_prog='C:\tools\miniconda3\envs\py27\python'
else
  set shell=/bin/sh
endif
" }}}

if (&term == "pcterm" || &term == "win32")
        set term=xterm t_Co=256
        let &t_AB="\e[48;5;%dm"
        let &t_AF="\e[38;5;%dm"
        set termencoding=utf8
        set nocompatible
        inoremap <Char-0x07F> <BS>
        nnoremap <Char-0x07F> <BS>
endif

"""""""""""""""""""""""""""""""""""""

" Mappings configurationn

"""""""""""""""""""""""""""""""""""""
" TODO check out Tim Popes unimpaired.vim plugin
nnoremap <silent> [b :bprevious<CR>
nnoremap <silent> ]b :bnext<CR>
nnoremap <silent> [B :bfirst<CR>
nnoremap <silent> ]B :blast<CR>

map <C-n> :NERDTreeToggle<CR>
map <C-m> :TagbarToggle<CR>
" Launch spelling check Toggle spell checking
nnoremap <>s :set invspell<CR> 
" Start interactive EasyAlign in visual mode (e.g. vipga)
" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)

nmap <>l <Plug>(Limelight)
xmap <>l <Plug>(Limelight)

" Open markdown files with Chrome.
autocmd BufEnter *.md exe 'noremap <F9> :!start chrome %:p<CR>'

" Enable folding with the spacebar
" nnoremap <space> za

" VIMUX
" Prompt for a command to run
"map <>vp :VimuxPromptCommand<CR>
" Run last command executed by VimuxRunCommand
"map <>vl :VimuxRunLastCommand<CR>
"map <>vip :call VimuxIpy()<CR>
"vmap <silent> <>e :python run_visual_code()<CR>
"noremap <silent> <>c :python run_cell(save_position=False, cell_delim='##')<CR>

" AsyncRun for compile and run.
" Quick run via <F5>
nnoremap <F9> :call <SID>compile_and_run()<CR>

function! s:compile_and_run()
    exec 'w'
    if &filetype == 'c'
        exec "AsyncRun! gcc % -o %<; time ./%<"
    elseif &filetype == 'cpp'
       exec "AsyncRun! g++ -std=c++11 % -o %<; time ./%<"
    elseif &filetype == 'java'
       exec "AsyncRun! javac %; time java %<"
    elseif &filetype == 'sh'
       exec "AsyncRun! time bash %"
    elseif &filetype == 'python'
       exec "AsyncRun! time python %"
    endif
endfunction

" Quickly navigate nvim panes (with ctrl direction)
" In TMUX same keys but with ALT
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
autocmd FileType python nnoremap <>= :0,$!yapf<CR>

" Bindings for nvim.ipy
let g:nvim_ipy_perform_mappings=0  "This resets the mappings
autocmd FileType python call SetPythonOptions()
function SetPythonOptions()
    map <silent> <c-s> <Plug>(IPy-Run) |
    map <silent> <c-c> <Plug>(IPy-RunCell) |
    map <silent> <F8> <Plug>(IPy-Interrupt) |
    map <silent> <c-f> <Plug>(IPy-Complete) |
    map <silent> <c-?> <Plug>(Ipy-WordObjInfo)
endfunction

" Iron.Nvim configuration:
" run 'luafile $HOME/AppData/nvim/iron.lua'
