"neovide settings
let g:neovide_cursor_vfx_mode = "ripple"
"let g:neovide_remember_window_size = v:true
let g:neovide_floating_opacity = 0.85
let g:neovide_refresh_rate = 60

set termguicolors
set guicursor=n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50
			\,a:blinkwait1000-blinkoff500-blinkon500-Cursor/lCursor,
			\sm:block-blinkwait175-blinkoff150-blinkon175
set shada="NONE"
"set guioptions=egrL

sil! call plug#begin()
if exists('*plug#begin')
	Plug 'tpope/vim-sensible'
	Plug 'fatih/vim-go', { 'tag': '*', 'do': ':GoInstallBinaries' }
	Plug 'rust-lang/rust.vim'
	"Plug 'govim/govim'
	Plug 'junegunn/vim-easy-align'
	Plug 'jreybert/vimagit'
	Plug 'junegunn/seoul256.vim'
	Plug 'mbbill/undotree'
	Plug 'ctrlpvim/ctrlp.vim'
	Plug 'justinmk/vim-sneak'
	"Plug 'rust-lang/rust.vim'
	Plug 'PProvost/vim-ps1', { 'for': 'ps1' }
	Plug 'inkarkat/vim-ingo-library'
	Plug 'inkarkat/vim-mark'
	Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
	Plug 'junegunn/fzf.vim'
	Plug 'glepnir/galaxyline.nvim' , {'branch': 'main'}
	Plug 'kyazdani42/nvim-web-devicons'
	"Plug 'akinsho/nvim-bufferline.lua'
	Plug 'mileszs/ack.vim'
	Plug 'preservim/nerdtree'
	Plug 'ryanoasis/vim-devicons'
	Plug 'tpope/vim-fugitive'
	Plug 'neoclide/coc.nvim', {'branch': 'release'}
	"Plug 'seblj/nvim-tabline'
	Plug 'romgrk/barbar.nvim'
	"Plug '~/vimfiles/plugged/after'
	call plug#end()

	let g:ctrlp_cmd = 'CtrlPMRU'
	let g:ctrlp_types = ['mru', 'fil', 'buf']
	let g:ctrlp_switch_buffer = 't'

	let $FZF_DEFAULT_OPTS = '--bind ctrl-a:select-all+accept'
	let g:fzf_preview_window = ['up:40%:hidden', 'ctrl-\']
	function! s:get_git_root()
		let root = split(system('git rev-parse --show-toplevel'), '\n')[0]
		if v:shell_error
			return ''
		endif
		if has('win32')
			let root = substitute(root, "/","\\","g")
		endif
		return root
	endfunction

	function! s:searchGit(arg)
		let root = s:get_git_root()
		let dict = fzf#vim#with_preview({'dir': root})
		call fzf#vim#grep("rg --column --line-number --no-heading --color=always --smart-case -- ".shellescape(a:arg)." ".root, 1, l:dict, 1)
	endfunction

	function! s:searchGitAll(arg)
		let root = s:get_git_root()
		let dict = fzf#vim#with_preview({'dir': root})
		call fzf#vim#grep("rg --column --line-number --no-heading --color=always --smart-case -uu -- ".shellescape(a:arg)." ".root, 1, l:dict, 1)
		"call fzf#vim#grep("ag --column --nogroup --color -- ".fzf#shellescape(a:arg)." ".root, 1, l:dict, 1)
	endfunction

	cnoremap <C-G><C-G> <C-R>=<SID>get_git_root()<CR>
	nnoremap <Space>f :FZF<space>
	nnoremap <Space>gf :GFiles!<CR>
	nnoremap <Space>gw :call <SID>searchGit(expand("<cword>"))<CR>
	nnoremap <Space>ga :call <SID>searchGit("")<CR>
	nnoremap <Space>w :call <SID>searchGitAll(expand("<cword>"))<CR>
	nnoremap <Space>a :call <SID>searchGitAll('^(?=.)')<CR>
	"nnoremap <space>w :Ag! <C-R><C-W><CR>
	"nnoremap <space>a :Ag!<CR>

	nnoremap <space>b :NERDTreeFind<CR>
	nnoremap <S-F12> :NERDTreeToggle<CR>

	let g:mwExclusionPredicates = []

	let g:sneak#label = 1
	map f <Plug>Sneak_f
	map F <Plug>Sneak_F
	map t <Plug>Sneak_t
	map T <Plug>Sneak_T

	vmap <Enter> <Plug>(LiveEasyAlign)

	nmap <Space>r <Plug>MarkRegex
	"nmap <Leader>m <Plug>MarkSet
	"vmap <Leader>m <Plug>MarkSet
	"nmap <Leader>M <Plug>MarkToggle
	"nmap <Leader>N <Plug>MarkAllClear
	let g:mwDefaultHighlightingPalette = 'extended'
	let g:mwMaxMatchPriority = -10
	let g:mwDirectGroupJumpMappingNum = 0

	let NERDTreeCustomOpenArgs = {'file':{'reuse':'all', 'where': 'p', 'keepopen': 0}, 'dir': {}}

	" coc.nvim setting
	set signcolumn=number
	inoremap <silent><expr> <TAB>
				\ pumvisible() ? "\<C-n>" :
				\ <SID>check_back_space() ? "\<TAB>" :
				\ coc#refresh()
	inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

	function! s:check_back_space() abort
		let col = col('.') - 1
		return !col || getline('.')[col - 1] =~# '\s'
	endfunction

	inoremap <silent><expr> <c-space> coc#refresh()
	"inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
	"			\: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

	nnoremap <silent> gd <Plug>(coc-definition)
	nnoremap <silent> gy <Plug>(coc-type-definition)
	nnoremap <silent> gi <Plug>(coc-implementation)
	nnoremap <silent> gr <Plug>(coc-references)

	nnoremap <silent> K :call <SID>show_documentation()<CR>

	function! s:show_documentation()
		if (index(['vim','help'], &filetype) >= 0)
			execute 'h '.expand('<cword>')
		elseif (coc#rpc#ready())
			call CocActionAsync('doHover')
		else
			execute '!' . &keywordprg . " " . expand('<cword>')
		endif
	endfunction

	nnoremap <leader>rn <Plug>(coc-rename)

	xmap <leader>f <Plug>(coc-format-selected)
	nmap <leader>f <Plug>(coc-format-selected)

	augroup mycocgroup
		autocmd!
		autocmd FileType typescript,java,json setl formatexpr=CocAction('formatSelected')
		autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
	augroup end

	xmap <leader>a <Plug>(coc-codeaction-selected)
	nmap <leader>a <Plug>(coc-codeaction-selected)

	nmap <leader>ac <Plug>(coc-codeaction)
	nmap <leader>qf <Plug>(coc-fix-current)

	command! -nargs=0 Format :call CocAction('format')
endif

if executable('ag')
	let g:ackprg = 'ag --vimgrep'
endif

let g:seoul256_background = 234
sil! color seoul256
syn on

set guifont=
			\JetBrainsMono\ NF,
			\Noto\ Sans\ CJK\ TC:h9
se cursorline
"hi LineNr guibg=#F0F0FF guifg=Brown
"hi CursorLine guibg=LightCyan
hi CursorLine guibg=#401020
hi DiffText guibg=#FF7F7F
"hi StatusLineNC	guibg=darkgrey guifg=white gui=none
"hi ModeMsg guibg=Purple guifg=white
hi User1	guibg=cyan guifg=black gui=none
hi ColorColumn guibg=#800040
"color default
"color desert
hi WarningMsg guifg=black guibg=green
hi NonText gui=bold guifg=#9F9FDF
hi SpecialKey gui=bold guifg=#7FDF7F
hi StatusLine guibg=#bbc2cf guifg=#303668

hi goSameId gui=bold guifg=yellow

"color dracula
"hi Search guifg=black guibg=#d1ca8c gui=underline
hi WarningMsg guifg=black guibg=#79ffc6
"hi ModeMsg guibg=Purple guifg=white
"hi LineNr guifg=#909194 guibg=#181a26

inoremap <C-S> <C-G>u<C-C>:W<CR>
nnoremap <C-S> :W<CR>
nnoremap <C-6> <C-^>

filetype plugin indent on

set grepprg=grep\ -nH\ $*
let g:tex_flavor='latex'
let g:Tex_HotKeyMappings='eqnarray*,eqnarray,bmatrix,mbox'

"rust
let g:rustfmt_autosave = 1
au filetype rust nmap <buffer> <leader>b :make check<CR>

"php
let g:PHP_default_indenting = 1

let g:zip_unzipcmd= "7z"

"java
let java_allow_cpp_keywords = 1

if has('mouse')
  set mouse=a
endif

"go
au filetype go nmap <buffer> <leader>r <Plug>(go-run)
au filetype go nmap <buffer> <leader>b <Plug>(go-build)
au filetype go nmap <buffer> <leader>ds <Plug>(go-def-split)
au filetype go nmap <buffer> <leader>gd <Plug>(go-doc)
au filetype go nmap <buffer> <leader>s <Plug>(go-implements)
au filetype go nmap <buffer> <leader>i <Plug>(go-info)
au filetype go nmap <buffer> <leader>t <Plug>(go-test)
au filetype go nmap <buffer> <leader>f <Plug>(go-referrers)
au filetype go nmap <buffer> <leader>l :GoSameIds<CR>
let g:go_fmt_command = "goimports"
"let g:go_auto_type_info = 1
let g:go_gocode_socket_type = 'tcp'
let g:go_textobj_enabled = 0
let g:go_template_autocreate = 0
let g:go_gocode_unimported_packages = 1
let g:go_highlight_build_constraints = 1
let g:go_build_tags="''"
"call govim#config#Set("FormatOnSave", "goimports")

set ts=4
set sw=4
"set nolbr
set showcmd
set display=lastline
set noea

"set noswf
set directory^=$HOME/vimswap//
"set dir=C:\temp\swap

"set fdm=syntax
"set nofen

set nu
set cin
set ai
set hidden
"set virtualedit=block
"set si
"set showmatch
"set cpoptions-=m

set hls is
set ignorecase smartcase

set nowrap
"set wrap
set linebreak

set so=3
set siso=3

if has("multi_byte")
	set encoding=utf8
	"change load file encoding
	nnoremap <silent> Zj :e ++enc=japan ++bad=keep<CR>
	nnoremap <silent> Zs :e ++enc=cp936 ++bad=keep<CR>
	nnoremap <silent> Zt :e ++enc=cp950 ++bad=keep<CR>
	nnoremap <silent> Zu :e ++enc=utf-8 ++bad=keep<CR>
	nnoremap <silent> Zl :e ++enc=latin1 ++bad=keep<CR>
	nnoremap <silent> Zb :e ++bin<CR>
	nnoremap <silent> ZJ :e ++enc=japan ++bad=keep<CR>
	nnoremap <silent> ZS :e ++enc=cp936 ++bad=keep<CR>
	nnoremap <silent> ZT :e ++enc=cp950 ++bad=keep<CR>
	nnoremap <silent> ZU :e ++enc=utf-8 ++bad=keep<CR>
	nnoremap <silent> ZL :e ++enc=latin1 ++bad=keep<CR>
	nnoremap <silent> ZB :e ++nobin<CR>
	"change save file encoding
	"nnoremap <silent> <C-M><C-j> :set fenc=japan<CR>
	"nnoremap <silent> <C-M><C-s> :set fenc=cp936<CR>
	"nnoremap <silent> <C-M><C-t> :set fenc=cp950<CR>
	"nnoremap <silent> <C-M><C-u> :set fenc=utf-8<CR>
	"nnoremap <silent> <C-M><C-l> :set fenc=latin1<CR>
	"nnoremap <silent> <C-M><C-b> :set bin<CR>
	"nnoremap <silent> <C-M><C-B> :set bin<CR>
	"nnoremap <silent> <C-M><C-m> :set bomb<CR>
	"nnoremap <silent> <C-M><C-M> :set bomb<CR>
	"nnoremap <silent> <C-M>j :set fenc=japan<CR>
	"nnoremap <silent> <C-M>s :set fenc=cp936<CR>
	"nnoremap <silent> <C-M>t :set fenc=cp950<CR>
	"nnoremap <silent> <C-M>u :set fenc=utf-8<CR>
	"nnoremap <silent> <C-M>l :set fenc=latin1<CR>
	"nnoremap <silent> <C-M>b :set nobin<CR>
	"nnoremap <silent> <C-M>B :set nobin<CR>
	"nnoremap <silent> <C-M>m :set nobomb<CR>
	"nnoremap <silent> <C-M>M :set nobomb<CR>
else
	echoerr "Sorry, this version of (g)vim was not compiled with multi_byte"
endif

"" CTRL-Tab is Next window
"noremap <silent> <C-Tab> <C-W>w
"inoremap <silent> <C-Tab> <C-O>gt
"cnoremap <silent> <C-Tab> <C-C>gt
"onoremap <silent> <C-Tab> <C-C>gt
""noremap <Tab> <C-W>w
"noremap <silent> <C-S-Tab> <C-W>W
"inoremap <silent> <C-S-Tab> <C-O>gT
"cnoremap <silent> <C-S-Tab> <C-C>gT
"onoremap <silent> <C-S-Tab> <C-C>gT

nnoremap <C-G> 2<C-G>
inoremap <silent> <C-U> <C-G>u<C-U>
"inoremap <silent> <C-W> <C-G>u<C-W>
"inoremap <silent> <C-G><C-W> <ESC>"_ciW
inoremap <silent> <C-G><C-W> <C-O>:let oldve=&ve<CR><C-O>:set ve=onemore<CR><C-O>"_dB<C-O>:set ve=<C-R>=oldve<CR><CR>
cnoremap <C-G><C-W> <C-\>eReplaceCmd(getcmdline(),getcmdpos(),'\S\+\s*')<CR>
cnoremap <C-G><C-U> <C-\>eReplaceCmd(getcmdline(),getcmdpos(),'[^\\/]\+[\\/]\?\s*')<CR>

"nnoremap <leader><bar> :set cc=<C-R>=
nnoremap <silent> <leader><bar> :set cc=<C-R>=(&cc=~'\<'.virtcol('.').'\>'?substitute(','.&cc.',',','.virtcol('.').',',',','')[1:-2]:(&cc==''?'':&cc.',').virtcol('.'))<CR><CR>
inoremap <C-L> <C-X><C-L>
inoremap <C-R>/ <c-r>=substitute(getreg('/'),'^\\<\\|\\>$','','g')<CR>

function! ReplaceCmd(cmdline, pos, pattern)
	if a:pos < 2
		return a:cmdline
	endif
	call setcmdpos(match(a:cmdline[0:a:pos-2],'^.\{-}\zs'.a:pattern.'$')+1)
	return matchstr(a:cmdline[0:a:pos-2],'^.\{-}\ze'.a:pattern.'$').a:cmdline[a:pos-1:-1]
endfunction

command! -nargs=? -bang -complete=file W :call <SID>SaveF("<args>","<bang>")

function! <SID>IsRoot(name)
	if a:name[0] == '/' || a:name[0] =='\'
		return 1
	endif
	let l:win = has("win16")||has("win32")||has("win64")
	if ! l:win
		return 0
	endif
	return match(a:name, ':[/\\]') >= 0
endfunction

function! <SID>ExtName(name)
	let l:path = a:name
	if len(a:name) == 0
		let l:path = expand('%:p')
	endif
	"return [a:name,"",a:name]
	if !<SID>IsRoot(l:path)
		let l:path = getcwd()."/".l:path
	endif
	let l:path = expand(l:path)
	let idx = match(l:path, '[^/\\]*$')
	if idx < 0
		return [l:path,"",l:path]
	endif
	return [l:path,l:path[:idx-1],l:path[idx :]]
endfunction

function! <SID>Warn(string)
	echohl WarningMsg
	echo a:string
	echohl None
endfunction

function! <SID>Error(string)
	echohl ErrorMsg
	echo a:string
	echohl None
endfunction

function! <SID>OK(string)
	return "y"==a:string || "Y"==a:string
endfunction

function! <SID>SaveF(name,bang)
	let p = <SID>ExtName(a:name)
	let path = p[0]
	let dir = p[1]
	let name = p[2]

	if !filewritable(dir) && !filereadable(dir) && !isdirectory(dir) && !isdirectory(path)
		"Try to create the folder
		call <SID>Warn('"Directory '.dir.'" not exists, press Y to create.')
		let l:reply = nr2char(getchar())
		if !<SID>OK(l:reply)
			echo "Cancelled"
			return
		endif
		sil! call mkdir(dir, 'p')
		if !isdirectory(dir)
			call <SID>Error('"'.dir.'" cannot be created')
			return
		endif
	endif

	let v:errmsg = ""
	let bang = a:bang
	while 1
		try
			exe "w".bang." " . path
		catch /\<\%(E13\|E45\|E505\)\>/
			"File exists | read only
			if exists("l:E13")
				call <SID>Error(substitute(v:exception,'^Vim\%((\a\+)\)\=:',"",""))
				break
			endif
			let l:E13 = 1
			if name == ""
				exe "confirm bro w ".getcwd()
				break
			endif
			if isdirectory(path)
				call <SID>Error('"'.name.'" is a directory')
				break
			endif
			if match(v:exception, '\<E13\>') >= 0
				call <SID>Warn('"'.name.'" exists, press Y to save.')
			else
				call <SID>Warn('"'.name.'" is read-only, press Y to save.')
			endif
			let l:reply = nr2char(getchar())
			if !<SID>OK(l:reply)
				echo "Cancelled"
				break
			endif
			let bang = "!"
			continue
		catch /\<E139\>/
			if exists("l:E139")
				call <SID>Error(substitute(v:exception,'^Vim\%((\a\+)\)\=:',"",""))
				break
			endif
			call <SID>Warn('"'.name.'" is loaded in another buffer, press Y to save.')
			let l:reply = nr2char(getchar())
			if !<SID>OK(l:reply)
				echo "Cancelled"
				break
			endif
			let l:E139 = 1
			let l:curfile = bufnr('%')
			let l:nextfile = bufnr('#')
			let l:count = 0
			while bufnr(path . l:count) > 0
				let l:count += 1
			endwhile
			let l:extbuf = bufnr(path)
			silent! exe "b ".l:extbuf
			silent! exe "f ".path . l:count
			silent! exe "b ".l:curfile
			continue
		catch /\<E32\>/
			exe "confirm bro w ".getcwd()
		catch
			call <SID>Error(substitute(v:exception,'^Vim\%((\a\+)\)\=:',"",""))
		endtry
		break
	endwhile
	if exists("l:E139")
		silent! exe "b ".l:extbuf
		silent! exe "f ".path
		silent! exe "e! ".path
		silent! exe "b ".l:nextfile
		silent! exe "b ".l:curfile
	endif
endfunction

map <MiddleMouse> <NOP>
inoremap <C-V> <C-G>u<C-R>+
nnoremap <C-V> "+gp
cnoremap <C-V> <MiddleMouse>
vnoremap <C-V> "+gp
nnoremap <silent> <C-C> "+y$
vnoremap <silent> <C-C> "+y

nnoremap <silent> Y y$
nnoremap <silent> y% :let @+=expand('%:p')<CR>:echo @+<CR>
nnoremap <silent> y<C-R>% :let @+=expand('%:t')<CR>:echo @+<CR>
nnoremap <silent> y<C-R><C-R>% :let @+=@%<CR>:echo @+<CR>

nmap <silent> <F2> :set scb!<CR>
nmap <silent> <F3> :set is!<CR>
nmap <silent> <C-F2> :sil !start explorer <c-r>=(expand('%')!=''?'/select,'.expand('%:p'):getcwd())<CR><CR>
nmap <silent> <F4> @@
nnoremap <silent> <F9> :<C-U>set wrap!\|if &wrap \| echo "Word wrap ON" \| else \| echo "Word wrap OFF"\|endif<CR>
inoremap <silent> <F9> <C-O>:set wrap!<CR>
nnoremap <silent> <S-F9> :set cursorline!<CR>

nnoremap <silent> <C-W><C-^> :vs #<CR>

nnoremap <silent> <C-N> :tab split<CR>
nnoremap <silent> <C-S-W> :tabc<CR>

nnoremap <silent> <C-S-Left> vb
nnoremap <silent> <C-S-Right> ve
nnoremap <silent> <S-Left> vh
nnoremap <silent> <S-Right> vl
nnoremap <silent> <S-Up> vk
nnoremap <silent> <S-Down> vj
inoremap <silent> <S-Left> <C-O>vh
inoremap <silent> <S-Right> <C-O>vl
inoremap <silent> <S-Up> <C-O>vk
inoremap <silent> <S-Down> <C-O>vj
vnoremap <silent> <S-Left> h
vnoremap <silent> <S-Right> l
vnoremap <silent> <S-Up> k
vnoremap <silent> <S-Down> j

nnoremap <silent> <C-J> gj
nnoremap <silent> <C-k> gk

nnoremap <silent> <M-;> @=':call search(''\u\+\\|_\+\zs\u*'', '''', line(''.''))'."\n"<CR>1<ESC>
nnoremap <silent> <M-,> @=':call search(''\u\+\\|_\+\zs\u*'', ''b'', line(''.''))'."\n"<CR>1<ESC>
vnoremap <silent> <M-;> :<C-U>exe "normal! gv"<Bar>call search('\u\+\\|_\+\zs\u*', '', line('.'))<CR>
vnoremap <silent> <M-,> :<C-U>exe "normal! gv"<Bar>call search('\u\+\\|_\+\zs\u*', 'b', line('.'))<CR>
onoremap <silent> <M-;> :call search('\u\+\\|_\+\zs\u*', '', line('.'))<CR>
onoremap <silent> <M-,> :call search('\u\+\\|_\+\zs\u*', 'b', line('.'))<CR>

vnoremap <M-/> <Esc>/\%><C-R>=line("'<")-1<CR>l\%<<C-R>=line("'>")+1<CR>l
vnoremap <M-?> <Esc>?\%><C-R>=line("'<")-1<CR>l\%<<C-R>=line("'>")+1<CR>l

map <silent> [9 [(
map <silent> ]0 ])
map <silent> ]9 ](
map <silent> [0 [)

let s:state = 0
let s:inc = 109
"algorithm from http://www.pcg-random.org/
let s:shiftDict = {
\0:1, 1:2, 2:4, 3:8, 4:16, 5:32, 6:64, 7:128, 8:256, 9:512, 10:1024, 11:2048,
\12:4096, 13:8192, 14:16384, 15:32768, 16:65536, 17:131072, 18:262144,
\19:524288, 20:1048576, 21:2097152, 22:4194304, 23:8388608, 24:16777216,
\25:33554432, 26:67108864, 27:134217728, 28:268435456, 29:536870912,
\30:1073741824, 31:2147483648, 32:4294967296, 33:8589934592, 34:17179869184,
\35:34359738368, 36:68719476736, 37:137438953472, 38:274877906944,
\39:549755813888, 40:1099511627776, 41:2199023255552, 42:4398046511104,
\43:8796093022208, 44:17592186044416, 45:35184372088832, 46:70368744177664,
\47:140737488355328, 48:281474976710656, 49:562949953421312,
\50:1125899906842624, 51:2251799813685248, 52:4503599627370496,
\53:9007199254740992, 54:18014398509481984, 55:36028797018963968,
\56:72057594037927936, 57:144115188075855872, 58:288230376151711744,
\59:576460752303423488, 60:1152921504606846976, 61:2305843009213693952,
\62:4611686018427387904,
\}
function! <SID>Pow2(in)
	return s:shiftDict[a:in]
endfunction

function! UintMul(large, x)
	if a:large >= 0
		return a:large * a:x
	endif
	let msb = -9223372036854775808 * and(a:x,1)
	let large = and(a:large, 9223372036854775807) * a:x
	return large + msb
endfunction

function! UintDiv(large, x)
	if a:large >= 0
		return a:large / a:x
	endif
	let mod = (2*(4611686018427387904 % a:x))/ a:x
	let msb = 4611686018427387904 / a:x
	let large = and(a:large, 9223372036854775807) / a:x
	return large + 2*msb + mod
endfunction

function! MyRandd()
	let oldstate = s:state
	let msb = 0
	let s:state = UintMul(oldstate,6364136223846793005) + or(s:inc,1)
	let xorshifted = and(UintDiv(xor(UintDiv(oldstate,262144), oldstate), 134217728), 4294967295)
	let rot = and(UintDiv(oldstate,576460752303423488), 4294967295)
	return and(or(xorshifted/<SID>Pow2(rot),(xorshifted*<SID>Pow2(and(4294967296-rot,31)))),4294967295)
endfunction
call MyRandd()
let s:state = s:state + localtime()
call MyRandd()

let g:MYRANDMAX = 4294967296.0
function! MyRandf()
	return (MyRandd()/g:MYRANDMAX)
endfunction

function! Rand(...)
	if a:0 == 1
		return float2nr(MyRandf()*a:1)
	elseif a:0 == 2
		let max = (a:1 > a:2 ? a:1 : a:2)
		let min = (a:1 > a:2 ? a:2 : a:1)
		return float2nr(MyRandf()*(max-min+1))+min
	endif
	return MyRandd()
endfunction

function! GenPwd(...)
	let l:len = 12
	if a:0 > 0
		if a:1 >= 4
			let l:len = a:1
		endif
	endif

	let l:lalpha = "abcdefghijklmnopqrstuvwxyz"
	let l:ualpha = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	let l:num = "0123456789"
	let l:sym = "`-=~!@#$%^&*()_+[]\{}|;':\",./<>?"

	let l:all = l:lalpha . l:ualpha . l:num . l:sym

	let l:pwd = []
	let l:pwd += [l:lalpha[Rand(len(l:lalpha))]]
	let l:pwd += [l:ualpha[Rand(len(l:ualpha))]]
	let l:pwd += [l:num[Rand(len(l:num))]]
	let l:pwd += [l:sym[Rand(len(l:sym))]]

	let i=4
	while i < l:len
		let l:pwd += [l:all[Rand(len(l:all))]]
		let i+=1
	endwhile
	let i=0
	while i < l:len
		let r = Rand(i,l:len-1)
		if r != i
			let tmp = l:pwd[i]
			let l:pwd[i] = l:pwd[r]
			let l:pwd[r] = tmp
		endif
		let i+=1
	endwhile
	return join(l:pwd,'')
endfunction

set autochdir

map <silent> Q gq

nnoremap <silent> <Space><Space> :call Auto_Highlight_Cword()\|set hls<CR>
function! Auto_Highlight_Cword()
	let word="\\<".expand("<cword>")."\\>"
	call histadd('/', word)
	"exe "let @/='\\<".expand("<cword>")."\\>'"
	let @/=word
endfunction

vnoremap <silent> <Space><Space> :call SelectionHighlight()<CR>
function! SelectionHighlight()
	let word = GetSelectionEscaped("enV")
	call histadd('/', word)
	call setreg('/', word)
endfunction

nnoremap <F12> :UndotreeToggle<CR>

nnoremap <M-/> :Ack -Q "
nnoremap <M-?> :AckAdd -Q "
cnoremap <M-/> <SPACE><C-R>=fnameescape(getcwd())<CR>/
cnoremap <M-?> <SPACE><C-R>=fnameescape(expand("%:p:h"))<CR>/
cnoremap <M-5> <SPACE><C-R>=fnameescape(expand('%:p'))<CR>
inoremap <M-/> <C-R>=fnameescape(expand("%:p:t"))<CR>
nmap <silent> <M-n> :cn<CR>
nmap <silent> <M-N> :cN<CR>
nnoremap <space>l :lad expand('%').':'.line('.').':'.getline('.')<CR>
cnoremap <C-R>^ <C-R>=fnameescape(expand('%:p:h'))<CR>/
inoremap <C-R>^ <C-R>=expand('%:p:h')<CR>/
cnoremap <C-R><C-L> <C-R>=getline('.')<CR>

inoremap <silent> <S-F7> <C-O>:set spell!<CR>
inoremap <silent> <F8> <C-O>:set list!<CR>
nnoremap <silent> <S-F7> :set spell!<CR>
nnoremap <silent> <F8> :set list!<CR>
nnoremap <silent> <M-F8> :let @z=@/<CR>:%s/\s\+$//<CR><C-O>:let @/=@z<CR>

"nmap <C-PageDown> G:sleep 1000m<CR>:call Auto_Scroll_Down()<CR><C-PageDown>
command! -nargs=? AutoScroll :call Auto_Scroll_Down('<args>')
let g:tmp_astimer = []
function! Auto_Scroll_Down(time)
	let l:time = str2nr(a:time)
	if l:time < 1000
		let l:time = 1000
	endif
	sil! call timer_stop(g:tmp_astimer)

	let tr = timer_start(l:time, '__Auto_Scroll_Down', {'repeat': -1})
	let g:tmp_astimer += [tr]
	nnoremap <ESC> :call _Cancel_Auto_Scroll()<CR>
endfunction

function! _Cancel_Auto_Scroll()
	for t in g:tmp_astimer
		call timer_stop(t)
	endfor
	sil! nunmap <ESC>
endfunction

function! __Auto_Scroll_Down(timer)
	if &modified
		call _Cancel_Auto_Scroll()
		return
	endif
	let l:isEnd = line('$') == line('.')
	e
	if l:isEnd
		keepjumps normal G
	endif
endfunction

function! GetSelectionEscaped(flags)
	" flags:
	"  "e" \  -> \\
	"  "n" \n -> \\n  for multi-lines visual selection
	"  "N" \n removed
	"  "V" \V added   for marking plain ^, $, etc.
	let save_a = @a
	silent normal! gv"ay
	let result = @a
	let @a = save_a
	let i = 0
	while i < strlen(a:flags)
		if a:flags[i] ==# "e"
			let result = escape(result, '\')
		elseif a:flags[i] ==# "n"
			let result = substitute(result, '\n', '\\n', 'g')
		elseif a:flags[i] ==# "N"
			let result = substitute(result, '\n', '', 'g')
		elseif a:flags[i] ==# "V"
			let result = '\V' . result
		endif
		let i = i + 1
	endwhile
	return result
endfunction

function! GetCard(str)
	let l:str = a:str
	let l:result = ''
	while strlen(l:str) > 0
		let l:card = l:str[0]
		if '1' ==# l:card
			let l:result = l:result . "SJ" . "\n"
		elseif '2' ==# l:card
			let l:result = l:result . "BJ" . "\n"
		else
			if 'M' >=# l:card
				let l:value = char2nr(l:card) - char2nr('A')
				let l:suit = "\U2660"
			elseif 'Z' >=# l:card
				let l:value = char2nr(l:card) - char2nr('N')
				let l:suit = "\U2661"
			elseif 'm' >=# l:card
				let l:value = char2nr(l:card) - char2nr('a')
				let l:suit = "\U2663"
			elseif 'z' >=# l:card
				let l:value = char2nr(l:card) - char2nr('n')
				let l:suit = "\U2662"
			endif
			if l:value == 12
				let l:value = 'K'
			elseif l:value == 11
				let l:value = 'Q'
			elseif l:value == 10
				let l:value = 'J'
			elseif l:value == 9
				let l:value = '10'
			elseif l:value == 0
				let l:value = 'A'
			else
				let l:value = nr2char(l:value + char2nr('1'))
			endif
			let l:result = l:result . l:suit . l:value . "\n"
		endif
		let l:str = l:str[1:]
	endwhile
	return l:result
endfunction

function! Range(start, ...)
	let l:result = []
	if a:0 == 2
		let l:lcount = float2nr(ceil((a:1-a:start)/a:2))
		let l:result = map(range(l:lcount>0 ? l:lcount : 0),'v:key*' . string(a:2) . '+' . string(a:start))
	elseif a:0 == 1
		let l:lcount = float2nr(ceil(a:1-a:start))
		let l:result = map(range(l:lcount>0 ? l:lcount : 0),'v:key+' . string(a:start))
	elseif a:0 == 0
		let l:lcount = float2nr(ceil(a:start))
		let l:result = map(range(l:lcount>0 ? l:lcount : 0),'v:key')
	else
		echoe "Too many arguments"
	endif
	return l:result
endfunction

function! Nr2str(num, ...)
	let l:symbol = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
	if a:0 > 0
		if a:1 >= 2 && a:1 <= 62
			let l:base = float2nr(a:1)
		else
			return ""
		endif
	else
		let l:base = 10
	endif
	if a:0 > 1
		let l:digit = a:2
	else
		let l:digit = float2nr(36.736801/log(l:base)+1)
	endif
	if type(a:num) == type(0)
		return (a:num > 0? _Nr2str(a:num, l:base, l:symbol) : '-' . _Nr2str(-a:num, l:base, l:symbol))
	elseif type(a:num) == type(0.1)
		return (a:num > 0? _Float2str(a:num, l:base, l:symbol, l:digit) : '-' . _Float2str(-a:num, l:base, l:symbol, l:digit))
	endif
endfunction

function! _Nr2str(num, base, symbol)
	let l:num = a:num
	let l:result = ''
	while l:num >= a:base
		let l:result = a:symbol[l:num % a:base] . l:result
		let l:num = l:num / a:base
	endwhile
	return a:symbol[l:num] . l:result
endfunction

function! _Float2str(num, base, symbol, digit)
	"let l:floor = float2nr(a:num)
	let l:num = floor(a:num)

	let l:result = ''
	while l:num >= a:base
		let l:result = a:symbol[float2nr(fmod(l:num, a:base))] . l:result
		let l:num = floor(l:num / a:base)
	endwhile
	let l:result = a:symbol[float2nr(l:num)] . l:result

	let l:num = a:num - floor(a:num)
	let l:dig = len(l:result)
	if l:dig < a:digit && l:num != 0
		let l:result = l:result . '.'
		while l:dig < a:digit && l:num != 0
			let l:floor = float2nr(l:num * a:base)
			let l:result = l:result . a:symbol[l:floor]
			let l:num = l:num * a:base - l:floor
			let l:dig += 1
		endwhile
	endif
	return l:result
endfunction

function! ParseFloat(str, base)
	if a:base < 2 || a:base > 62
		throw 'Base must be between 2 and 62'
	endif
	let l:symbol = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'[:float2nr(a:base) -1]
	let l:str = (a:base > 36 ? a:str : toupper(a:str))
	if str[0] == '-'
		return -1*_ParseFloat(toupper(l:str[1:]), a:base, l:symbol)
	else
		return _ParseFloat(toupper(l:str), a:base, l:symbol)
	endif
endfunction

function! _ParseFloat(str, base, symbol)
	if a:base < 2 || a:base > len(a:symbol)
		throw 'Base must be between 2 and '.len(a:symbol)
	endif
	let l:str = substitute(a:str, '\C^[^-.'.a:symbol.']*', '', '')
	let l:str = substitute(l:str, '\C^[-.'.a:symbol.']*\zs.*', '','')
	let intstr = matchstr(l:str, '[^.]*')
	let decstr = matchstr(l:str, '\.\zs[^.]*')
	let result = 0.0
	let decimal = 0.0
	while len(l:intstr) > 0
		let l:result = stridx(a:symbol, l:intstr[0]) + l:result * a:base
		let l:intstr = l:intstr[1:]
	endwhile
	while len(l:decstr) > 0
		let l:decimal = stridx(a:symbol, l:decstr[-1:]) + l:decimal / a:base
		let l:decstr = l:decstr[:-2]
	endwhile
	return l:result + l:decimal / a:base
endfunction

set lcs=tab:\|`,eol:$,nbsp:@,trail:#,extends:>

set spellsuggest=double

:dig sS 9828
:dig sH 9829
:dig sC 9831
:dig sD 9830
:dig *. 8729
:dig V< 11168
:dig V> 11169
:dig ^< 11170
:dig ^> 11171
:dig <^ 11172
:dig >^ 11173
:dig <V 11174
:dig >V 11175

set noshowmode
"set statusline=%(%#ModeMsg#%{GetMode()}%*\ %)%(\ %1*%r%*\ %)%(%Y\|%)%(%M\|%)\ %{expand('%')==expand('%:t')?'':'…/'}%t%<%{GetCacheFTimeStr()}%=%k[0x%02B]\ [%{GetFF().','.AliasEnc().','.AliasEnc('f')}]%{(&scb==1?'B':'').(&wrap==1?'W':'')}\ %-5.(%l,%c%V%)\ %P
set laststatus=2
set backspace=2

function! GetMode()
	if g:myFocus != winnr()
		return ""
	endif
	let l:k = mode(" ")
	let l:m = ""
	while !has_key(g:myMode, l:k)
		if len(l:k) <= 1
			return ""
		endif
		let l:k = l:k[0:-2]
		let l:m = "?"
	endwhile
	return l:m . g:myMode[l:k]
endfunction
let g:myFocus = 1
au WinEnter * let g:myFocus = winnr()

au BufRead,BufNewFile,BufFilePost,BufWritePost *			call CacheBufPara()
function! CacheBufPara()
	let b:Ftime = getftime(expand('%:p'))
	if b:Ftime <= 0
		let b:FtimeStr = ''
		return
	endif
	let ltime = localtime()
	let fdate = strftime(' %Y-%m-%d', b:Ftime)
	let ldate = strftime(' %Y-%m-%d', ltime)
	if fdate == ldate
		let b:FtimeStr = strftime(' %H:%M:%S',b:Ftime)
	elseif fdate[1:4] == ldate[1:4]
		let b:FtimeStr = strftime(' %m-%d %H:%M:%S',b:Ftime)
	else
		let b:FtimeStr = fdate . strftime(' %H:%M:%S',b:Ftime)
	endif
	"let b:FPath = expand('%:p:~:h')
endfunction

function! GetCacheFTime()
	"let l:time = getftime(expand('%:p'))
	if !exists('b:Ftime')
		if expand('%:p') ==# '' || !&ma
			let b:Ftime = ''
		else
			call CacheBufPara()
		endif
		"return ' (Invalid)'
	endif
	return b:Ftime
endfunction

function! GetCacheFTimeStr()
	"let l:time = getftime(expand('%:p'))
	if !exists('b:FtimeStr')
		if expand('%:p') ==# '' || !&ma
			let b:FtimeStr = ''
		else
			call CacheBufPara()
		endif
		"return ' (Invalid)'
	endif
	return b:FtimeStr
endfunction

function! GetCachePath()
	if exists('b:FPath')
		return b:FPath
	endif
	return ''
endfunction

function! GetFF()
	return &binary?"bin":&ff
endfunction

let myMode = {}
let myMode['n']      = ''
let myMode['no']     = 'OP-PEND'
let myMode['v']      = 'VISUAL'
let myMode['V']      = "V-LINE"
let myMode["\<C-V>"] = 'V-BLOCK'
let myMode["s"]      = 'SELECT'
let myMode["S"]      = 'S-LINE'
let myMode["\<C-S>"] = 'S-BLOCK'
let myMode["i"]      = 'INS'
let myMode["ic"]     = 'INS-CMD'
let myMode["Rv"]     = 'V-REPLACE'
let myMode["R"]      = 'REPLACE'
let myMode["c"]      = 'COMMAND'
let myMode["cv"]     = 'VIM-EX'
let myMode["ce"]     = 'NORM-EX'
let myMode["r"]      = 'PROMPT'
let myMode["rm"]     = ''
let myMode["r?"]     = ''
let myMode["!"]      = 'EXT-CMD'

function! GetMode()
	if g:myFocus != winnr()
		return ""
	endif
	let l:k = mode(" ")
	let l:m = ""
	while !has_key(g:myMode, l:k)
		if len(l:k) <= 1
			return ""
		endif
		let l:k = l:k[0:-2]
		let l:m = "?"
	endwhile
	return l:m . g:myMode[l:k]
endfunction

function! AliasEnc()
	if &binary
		return "bin"
	endif
	let lenc = &fenc
	if lenc =~ "^$"
		return "U8"
	elseif lenc =~ "utf-8"
		let lenc = "U8"
	elseif lenc =~ "cp950"
		let lenc = "B5"
	elseif lenc =~ "cp936"
		let lenc = "GB"
	elseif lenc =~ "cp932"
		let lenc = "JP"
	endif
	if &bomb
		return lenc."m"
	endif
	return lenc
endfunction

"lua require('top-bufferline')
lua require('top-tabline')
lua require('statusline')
lua require('file-icons')
