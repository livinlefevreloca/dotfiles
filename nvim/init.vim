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
Plug 'rakr/vim-two-firewatch'
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
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>qq :q!<CR>
nnoremap <leader>wq :wq<CR>
nnoremap <leader><leader> <c-w>w
nmap <leader> <c-w>
nnoremap <C-d> jjjjj
nnoremap <C-u> kkkkk
nnoremap <leader>n :tabn<CR>
nnoremap <leader>p :tabp<CR>
nnoremap <leader>t :tabnew<CR>
nnoremap <leader>c :tabc<CR>
nnoremap <silent> <leader>b :set relativenumber!<CR>
nnoremap <silent> <leader>B :set nu!<CR>
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
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

"map toggle
map <C-n> :NERDTreeToggle<CR>
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




"Scripts
"==================================================================================================================================================
" Scipts to help productivity
"==================================================================================================================================================
" copy all matches into a buffer
function! CopyMatches(reg)
  let hits = []
  %s//\=len(add(hits, submatch(0))) ? submatch(0) : ''/gne
  let reg = empty(a:reg) ? '+' : a:reg
  execute 'let @'.reg.' = join(hits, "\n") . "\n"'
endfunction
command! -register CopyMatches call CopyMatches(<q-reg>)

 
"Colors
syntax on
set background=dark " or light if you prefer the light version
colorscheme NeoSolarized
let g:lightline = { 'colorscheme': 'lightline_solarized' }
hi TabLineSel ctermfg=Red ctermbg=white


