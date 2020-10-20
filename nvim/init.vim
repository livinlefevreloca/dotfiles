" General settings
"==================================================================================================================================================
" General setting for ideak nvim usage
"==================================================================================================================================================

set number
set norelativenumber
set nobackup
set nowritebackup
set nowrap
set laststatus=2
set completeopt=preview
set tabstop=4
set shiftwidth=4
set expandtab
set cursorline
set termguicolors
set list
set listchars=eol:↩
set ffs=unix
" auto commands
autocmd Filetype yaml set tabstop=2 | set shiftwidth=2
" Instantiate Plugins
"==================================================================================================================================================
" Plugins installed for use with nvim
"==================================================================================================================================================
call plug#begin('~/.config/nvim/plugged')
Plug 'preservim/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'neoclide/coc-python'
Plug 'terryma/vim-multiple-cursors'
Plug 'easymotion/vim-easymotion'
Plug 'itchyny/lightline.vim'
Plug 'overcache/NeoSolarized'
Plug 'taohexxx/lightline-solarized'
Plug 'hashivim/vim-terraform'
call plug#end()

"General mappings
"==================================================================================================================================================
" Mappings for general nvim usage
"==================================================================================================================================================

"leader
let mapleader=' '

" insert mappings
imap ii <Esc>

" reselect visual block after shifting indentation
vnoremap < <gv
vnoremap > >gv

" normal mappings
nnoremap <c-s> :source ~/.config/nvim/init.vim<CR>
nnoremap <silent> <c-c> :tabedit ~/.config/nvim/init.vim<CR>
nnoremap <C-k> O<ESC>j 
nnoremap <C-j> o<ESC>k
nnoremap <C-t> :tab terminal<CR>i

" terminal mappings
:tnoremap <Esc> <C-\><C-n>



" ex mappings
xnoremap ii  <ESC> 

" visual mappings
vnoremap ii <ESC> 
vnoremap <leader>y :w !pbcopy<CR><CR>
" leader short cuts
nnoremap <leader>w :wa<CR>
nnoremap <leader>q :x<CR>
nnoremap <leader>qa :xa<CR>
nnoremap <leader>qq :q!<CR>
nnoremap <leader><leader> <c-w>w
nnoremap <C-d> jjjjj
nnoremap <C-u> kkkkk
nnoremap <leader>n :tabn<CR>
nnoremap <leader>p :tabp<CR>
nnoremap <leader>t :tabnew<CR>
nnoremap <leader>c :tabc<CR>
nnoremap <silent> <leader>b :set relativenumber!<CR>
nnoremap <silent> <leader>B :set nu!<CR>
nnoremap <silent> <leader>l :set listchars=<CR>
nnoremap <silent> <leader>L :set listchars=eol:↩<CR>

" Plugin specifics
"==================================================================================================================================================
" Settings for plugins used with neovim
"==================================================================================================================================================




">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
" Nerdtree 
">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
" open Nerdtree on startup
autocmd vimenter * NERDTree | wincmd p
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | exe 'cd '.argv()[0] | endif
" close vim if nerd tree is the only window left
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERiDTree") && b:NERDTree.isTabTree()) | q | endif
let g:NERDTreeWinSize=25

"map toggle
map <C-x> :NERDTreeToggle<CR>
nnoremap <leader>v :call NERDTreeLivePreview()<CR>
nnoremap <leader>V <C-w>j :q!<CR>
" prevent crashes due to vim-plug
let g:plug_window = 'noautocmd vertical topleft new'
">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
" Nerdtree End
">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>




">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
" Coc-vim 
">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
nmap <leader>d :w<CR><Plug>(coc-definition)
nmap <leader>y :w<CR><Plug>(coc-type-definition)
nmap <leader>i :w<CR><Plug>(coc-implementation)
nmap <leader>r <Plug>(coc-references)

let g:coc_user_config = {"python.pythonPath":"/Users/adam.lefevre/anaconda3/bin/python3", "python.jediEnabled": "false"}
">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
" Coc-vim end
">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
" terraform 
">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
let g:terraform_fmt_on_save=1

">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
" terraform end
">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
" fzf 
">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

nnoremap <leader>ff :Files<CR>
nnoremap <leader>f :Files
nnoremap <leader>s :Rg<CR>

">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
"fzf end
">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
" multiple cursors 
">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
let g:multi_cursor_use_default_mapping=0

" Default mapping
let g:multi_cursor_start_word_key      = '<C-n>'
let g:multi_cursor_select_all_word_key = '<C-a>'
let g:multi_cursor_start_key           = 'g<C-n>'
let g:multi_cursor_select_all_key      = 'g<C-a>'
let g:multi_cursor_next_key            = '<C-n>'
let g:multi_cursor_prev_key            = '<C-p>'
let g:multi_cursor_skip_key            = '<C-x>'
let g:multi_cursor_quit_key            = '<Esc>'

">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
"end multiple cursors
">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
"easymotion
">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
map xx <Plug>(easymotion-prefix)
">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
"end easymotion
">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
"
"
"Colors
syntax on
set background=dark " or light if you prefer the light version
colorscheme NeoSolarized
let g:lightline = { 'colorscheme': 'lightline_solarized' }
hi TabLineSel ctermfg=Red ctermbg=white
"hi! EndOfBuffer ctermbg=bg ctermfg=bg guibg=bg guifg=bg


