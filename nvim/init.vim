set nrformats=
set cmdheight=2
let mapleader = "\<Space>"
autocmd vimenter * NERDTree
syntax on

call plug#begin('~/.config/nvim/plugged')

" visual
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'fcpg/vim-orbital'

" misc 
Plug 'preservim/nerdtree'
Plug 'jiangmiao/auto-pairs'


" fuzzy finder
Plug 'airblade/vim-rooter'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

" Language support
Plug 'dense-analysis/ale'
Plug 'rust-lang/rust.vim'
Plug 'plasticboy/vim-markdown'
call plug#end()

" ale options set linters
let b:ale_fixers = {'javascript': ['eslint'], 'python': ['black']}
let g:ale_completion_tsserver_autoimport = 1

" terminal
:tnoremap <Esc> <C-\><C-n>

" mappings
imap jj <Esc>
" tab bindings
map  <C-l> :tabn<CR>
map  <C-h> :tabp<CR>
map  <C-n> :tabnew<CR>
" nerdtree toggle
map <C-q> :NERDTreeToggle<CR>
" init.vim bindings
map <C-c> :e ~/.config/nvim/init.vim<CR>
map <C-x> :source ~/.config/nvim/init.vim<CR>
" leader maps
nnoremap <leader><leader> <c-w><c-w>
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>t :terminal<CR>i
nnoremap <leader>g :ALEGoToDefinition<CR>
nnoremap <leader>f :ALEFindReferences<CR>


colorscheme orbital
set t_Co=256
set t_AB=^[[48;5;%dm
set t_AF=^[[38;5;%dm
