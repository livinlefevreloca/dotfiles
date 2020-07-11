" General settings
"==================================================================================================================================================
" General setting for ideak nvim usage
"==================================================================================================================================================
set number 
set relativenumber
set nobackup
set nowritebackup
set nowrap
set laststatus=2
set completeopt-=preview
set tabstop=4
set shiftwidth=4
set expandtab
set cursorline
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


" Ctrl-j/k deletes blank line below/above, and Alt-j/k inserts.
nnoremap <C-k> O<ESC> 
nnoremap <C-j> o<ESC>

" ex mappings
xnoremap ii  <ESC> 

" visual mappings
vnoremap ii <ESC> 

" leader short cuts
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>qq :q!<CR>
nnoremap <leader>wq :wq<CR>
nnoremap <leader><leader> <c-w>w
nnoremap <leader>n :tabn<CR>
nnoremap <leader>p :tabp<CR>
nnoremap <leader>t :tabnew<CR>
nnoremap <leader>c :tabc<CR>
" Plugin specifics
"==================================================================================================================================================
" Settings for plugins used with neovim
"==================================================================================================================================================




">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
" Nerdtree 
">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
" open Nerdtree on startup
autocmd vimenter * NERDTree | wincmd p

" close vim if nerd tree is the only window left
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

"map toggle
map <C-n> :NERDTreeToggle<CR>
nmap <C-r> :NERDTreeFocus<cr>R<c-w><c-p>
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
nmap <leader>i :<CR><Plug>(coc-implementation)
nmap <leader>r <Plug>(coc-references)

let g:coc_user_config = {"python.pythonPath":"/Users/adam.lefevre/anaconda3/bin/python3", "python.jediEnabled": "false"}
">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
" Coc-vim end
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
let g:two_firewatch_italics=1
colo two-firewatch
let g:lightline = { 'colorscheme': 'seoul256' }

hi Pmenu          guifg=#f6f3e8     guibg=#444444     gui=NONE      ctermfg=NONE        ctermbg=NONE        cterm=NONE
