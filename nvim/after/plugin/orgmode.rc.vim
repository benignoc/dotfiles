" orgmode config
" lua << EOF
" require('orgmode').setup({
"   org_agenda_files = {'~/Documents/Notes/org/*'},
"   org_default_notes_file = '~/Documents/Notes/org/refile.org',
" })
" EOF

" 
lua << EOF
local parser_config = require "nvim-treesitter.parsers".get_parser_configs()
parser_config.org = {
  install_info = {
    url = 'https://github.com/milisims/tree-sitter-org',
    revision = 'main',
    files = {'src/parser.c', 'src/scanner.cc'},
  },
  filetype = 'org',
}

require'nvim-treesitter.configs'.setup {
  -- If TS highlights are not enabled at all, or disabled via `disable` prop, highlighting will fallback to default Vim syntax highlighting
  highlight = {
    enable = true,
    disable = {'org'}, -- Remove this to use TS highlighter for some of the highlights (Experimental)
    additional_vim_regex_highlighting = {'org'}, -- Required since TS highlighter doesn't support all syntax features (conceal)
  },
  ensure_installed = {'org'}, -- Or run :TSUpdate org
}

require('orgmode').setup({
  org_agenda_files = {'~/Documents/Notes/org/*'},
  org_default_notes_file = '~/Documents/Notes/org/refile.org',
  org_hide_leading_stars = true,
  org_todo_keywords = {'TODO(t)', 'MEET(m)', 'WAIT(w)', 'ASSIGN(a)', '|', 'DONE(d)', 'DROPED(D)'},
})
EOF

