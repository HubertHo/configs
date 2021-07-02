setlocal colorcolumn=101
setlocal textwidth=120

" PDB shortcut
nmap <buffer> <Leader>pdb o__import__("pdb").set_trace()<Esc>

" Python syntax options
let g:python_highlight_string_format=1
let g:python_highlight_string_templates=1
let g:python_highlight_func_calls=1
let g:python_highlight_class_vars=1

echom 'Loaded python plugin'
echo 'Loaded python plugin'
