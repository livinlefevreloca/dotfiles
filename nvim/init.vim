"==================================================================================================================================================
" General setting for ideak nvim usage

set number
set noswapfile
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
set splitright
set clipboard^=unnamed
"set mouse=a
set ffs=unix
" auto commands

autocmd!
autocmd filetype {yaml,tsx,sh} set tabstop=2 | set shiftwidth=2
autocmd BufEnter *.{js,jsx,ts,tsx} :syntax sync fromstart
autocmd BufLeave *.{js,jsx,ts,tsx} :syntax sync clear
autocmd FileType python let b:coc_root_patterns = ['.git']
autocmd FileType python set colorcolumn=95
autocmd FileType python vnoremap <C-c> :normal I# <CR>
autocmd FileType python vnoremap <silent> <C-u> :s/# // <CR>:noh<CR>
autocmd FileType go vnoremap <C-c> :normal I// <CR>
autocmd FileType go vnoremap <silent> <C-u> :s/\/\/ // <CR>:noh<CR>

command Vconf :e $MYVIMRC
command! -nargs=+ Capture let @s = trim(system(join([<f-args>], ' ')))
" =================================================================================================================================================
" Window Commands
" =================================================================================================================================================

nnoremap <silent> vgF <C-W>vgF
nnoremap <silent> vgf <C-W>vgf


" =================================================================================================================================================
" Kill trailing white space
" =================================================================================================================================================

function! TrimWhitespace()
    let l:save = winsaveview()
    keeppatterns %s/\s\+$//e
    call winrestview(l:save)
endfunction

augroup TrimWhitespace
    autocmd!
    autocmd BufWritePre * :call TrimWhitespace()
augroup END



" Instantiate Plugins
"==================================================================================================================================================
" Plugins installed for use with nvim
"==================================================================================================================================================
call plug#begin('~/.config/nvim/plugged')
"Plug 'preservim/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'neoclide/coc-python'
Plug 'jackguo380/vim-lsp-cxx-highlight'
Plug 'vim-syntastic/syntastic'
Plug 'machakann/vim-highlightedyank'
" Style
Plug 'overcache/NeoSolarized'
Plug 'scottmckendry/cyberdream.nvim'
Plug 'itchyny/lightline.vim'
Plug 'taohexxx/lightline-solarized'
" terraform
Plug 'hashivim/vim-terraform'
Plug 'juliosueiras/vim-terraform-completion'
" for typescript and react
Plug 'pangloss/vim-javascript'
Plug 'leafgarland/typescript-vim'
Plug 'peitalin/vim-jsx-typescript'
Plug 'styled-components/vim-styled-components', { 'branch': 'main' }
" github plugins
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'
" for smooth scrolling
Plug 'psliwka/vim-smoothie'
" for diffview
Plug 'sindrets/diffview.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'kyazdani42/nvim-web-devicons'
" for github copilot
Plug 'github/copilot.vim'
" jupyter notebooks in vim
call plug#end()
"

"General mappings
"==================================================================================================================================================
" Mappings for general nvim usage
"==================================================================================================================================================
"leader

let mapleader=','

" insert mappinigs
inoremap <silent> <c-u> <esc>viwU<esc>a
" normal mappings
"nnoremap <silent> <C-s> :source $MYVIMRC<CR>
nnoremap <C-g> :echo expand('%:p')<CR>
nnoremap <silent> \\ :noh<CR>
nnoremap <silent> <C-l> :set relativenumber!<CR>

nnoremap <silent> <C-k> :m .-2<CR>
nnoremap <silent> <C-j> :m .+1<CR>

" visual mappings
vnoremap <leader>g :GBrowse<CR>
vnoremap < <gv
vnoremap > >gv

" leader short cuts
nnoremap <leader>c :tabc<CR>
nnoremap <leader>g :GBrowse<CR>
nnoremap <leader>k O<ESC>j
nnoremap <leader>j o<ESC>k
nnoremap <silent> <leader>e :Ex<CR>
nnoremap <silent> <leader>ve :Vex<CR>
nnoremap <silent> <leader>se :Sex<CR>

tnoremap <silent> <leader><ESC> <C-\><C-n>

"==================================================================================================================================================
" Settings for plugins used with neovim
"==================================================================================================================================================

">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
" Coc-vim
">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
" Coc specific mapppings

let g:coc_global_extensions = ['coc-jedi', 'coc-pyright', 'coc-rust-analyzer', 'coc-tslint-plugin', 'coc-tsserver', 'coc-emmet', 'coc-css', 'coc-html', 'coc-json', 'coc-yank', 'coc-prettier', 'coc-lua', 'coc-go', 'coc-elixir', 'coc-vimlsp', 'coc-sql', 'coc-zig']
""" Customize colors
func! s:my_colors_setup() abort
    hi CocFloating guibg=#30313d
endfunc

augroup colorscheme_coc_setup | au!
    au ColorScheme * call s:my_colors_setup()
augroup END

" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
set signcolumn=yes

" Use tab for trigger completion with characters ahead and navigate.
" NOTE: There's always complete item selected by default, you may want to enable
" no select by `"suggest.noselect": true` in your configuration file.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

" Make <CR> to accept selected completion item or notify coc.nvim to format
" <C-g>u breaks current undo, please make your own choice.
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif

" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nnoremap <silent> sgd :call CocAction('jumpDefinition', 'split ')<CR>
nnoremap <silent> vgd :call CocAction('jumpDefinition', 'vs ')<CR>
nnoremap <silent> tgd :call CocAction('jumpDefinition', 'tab drop ')<CR>
nnoremap <silent> sgr :call CocAction('jumpReferences', 'split ')<CR>
nnoremap <silent> vgr :call CocAction('jumpReferences', 'vs ')<CR>
nnoremap <silent> tgr :call CocAction('jumpReferences', 'tab drop ')<CR>


" Use K to show documentation in preview window.
nnoremap <silent> K :call ShowDocumentation()<CR>

function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

" Formatting selected code.
xmap \f  <Plug>(coc-format-selected)
nmap \f  <Plug>(coc-format-selected)

augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder.
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Applying codeAction to the selected region.
" Example: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap keys for applying codeAction to the current buffer.
nmap <leader>ac  <Plug>(coc-codeaction)
" Apply AutoFix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)

" Run the Code Lens action on the current line.
nmap <leader>cl  <Plug>(coc-codelens-action)

" Remap <C-f> and <C-b> for scroll float windows/popups.
if has('nvim-0.4.0') || has('patch-8.2.0750')
  nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
  inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
  inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
  vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
endif

" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocActionAsync('format')


" Prevent vim-go from removing imports
let g:go_fmt_command = "gofmt"


">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
" terraform
">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
let g:terraform_fmt_on_save=1

">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
" fzf
">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
nnoremap <silent> <leader>f  :Files<CR>
nnoremap <leader>F :Files $ALBERT_PROJECTS<CR>
nnoremap <leader>d :Files %:h<CR>
nnoremap <leader>s :Rg<CR>
"nnoremap <leader>S :call fzf#vim#grep("rg --column --line-number --no-heading --smart-case '.*' /Users/adamlefevre/Projects/albert/ --".shellescape(""), fzf#vim#with_preview(), 0)<CR>
nnoremap <leader>b :Buffers<CR>
nnoremap <leader>h :History:<CR>
nnoremap <leader>hf :History<CR>
nnoremap <leader>hs :History/<CR>
nnoremap <leader>gf :GFiles?<CR>

fun! s:append_selection(lines)
    call appendbufline(bufnr('%'), 0, a:lines)
endfunction

">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
"c++
">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
let g:cpp_class_scope_highlight = 1
let g:cpp_member_variable_highlight = 1
let g:cpp_class_decl_highlight = 1


">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
" lightline
">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
let g:lightline = {
            \ 'colorscheme': 'lightline_solarized',
            \ 'active': {
            \   'left': [ [ 'mode', 'paste' ],
            \             [ 'readonly', 'filename', 'modified', 'gitbranch' ] ]
            \ },
            \ 'component_function': {
            \   'gitbranch': 'FugitiveHead',
            \ },
\ }

">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
"Colors
">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
syntax on
set background=dark " or light if you prefer the light version
colorscheme NeoSolarized
hi TabLineSel ctermfg=Red ctermbg=white

">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
" Syntastic
">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
let g:syntastic_mode_map = {
    \ "mode": "passive",
    \ "active_filetypes": ["sh"],
    \ "passive_filetypes": ["python"] }

" Terraform autocomplete
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

" (Optional)Remove Info(Preview) window
set completeopt-=preview

" (Optional)Hide Info(Preview) window after completions
"autocmd CursorMovedI * if pumvisible() == 0|pclose|endif
"autocmd InsertLeave * if pumvisible() == 0|pclose|endif

" (Optional) Enable terraform plan to be include in filter
let g:syntastic_terraform_tffilter_plan = 1

" (Optional) Default: 0, enable(1)/disable(0) plugin's keymapping
let g:terraform_completion_keys = 0

" (Optional) Default: 1, enable(1)/disable(0) terraform module registry completion
let g:terraform_registry_module_completion = 0

">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
" Custom netrw settings
">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
let g:netrw_preview = 1

">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
" PSQL helpers
">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
fun! s:search_psqlh()
    silent exec "!test -e /tmp/psql_history && rm /tmp/psql_history &> /dev/null"
    exec "vs /tmp/psql_history"
    silent exec "r ~/.psql_history"
    silent exec "%s/\\\\040/ /g"
    silent exec "%s/134/\/g"
    silent exec "%s/\\\\\^A/ /g"
    normal! gg
    silent exec "x"
    call fzf#run(fzf#wrap({'source': "cat /tmp/psql_history | sort -u | tr '[:upper:]' '[:lower:]'", 'sink': function('s:append_selection')}))
endfun

command! SearchPSQL :call s:search_psqlh()
command! SQLFormat :%!sqlformat --reindent --keywords upper --identifiers lower -

augroup sql
    au!
    au BufRead,BufNewFile *.sql set filetype=sql
    au BufEnter *.sql nnoremap <silent> <C-f>  :SQLFormat<CR>
augroup END
