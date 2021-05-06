set nocp

sil! call plug#begin()
if exists('*plug#begin')
	Plug 'tpope/vim-sensible'
	Plug 'junegunn/vim-easy-align'
	Plug 'jreybert/vimagit'
	Plug 'junegunn/seoul256.vim'
	Plug 'mbbill/undotree'
	Plug 'fatih/molokai'
	Plug 'ctrlpvim/ctrlp.vim'
	Plug 'junegunn/fzf', {'do': './install --all'}
	Plug 'justinmk/vim-sneak'
	Plug 'inkarkat/vim-ingo-library'
	Plug 'inkarkat/vim-mark'
	call plug#end()

	nnoremap <M-'> :CtrlP<CR>
	let g:ctrlp_switch_buffer = 'et'
	let g:ctrlp_cmd = 'CtrlPMRU'
	let g:ctrlp_types = ['mru', 'fil', 'buf']

	vmap <CR> <Plug>(LiveEasyAlign)

	"go
	au filetype go nmap <leader>r <Plug>(go-run)
	au filetype go nmap <leader>b <Plug>(go-build)
	au filetype go nmap <leader>dd <Plug>(go-def)
	au filetype go nmap <leader>ds <Plug>(go-def-split)
	au filetype go nmap <leader>dt <Plug>(go-def-tab)
	au filetype go nmap <leader>dv <Plug>(go-def-vertical)
	au filetype go nmap <leader>gd <Plug>(go-doc)
	au filetype go nmap <leader>s <Plug>(go-implements)
	au filetype go nmap <leader>i <Plug>(go-info)
	au filetype go nmap <leader>f <Plug>(go-referrers)
	au filetype go nmap <leader>t <Plug>(go-test)
	au filetype go nmap <leader>l :GoSameIds<CR>
	"let g:go_auto_type_info = 1
	"let g:go_textobj_enabled = 0
	let g:go_highlight_build_constraints = 1
	let g:go_template_autocreate = 0
	let g:go_fmt_command = "goimports"
	let g:go_gocode_socket_type = 'tcp'
	let g:go_gocode_unimported_packages = 1
	let g:go_gopls_unimported_packages = 1
	let g:go_highlight_build_constraints = 1
	let g:go_build_tags = "''"
	"let g:go_auto_sameids = 1

	let g:sneak#label = 1

	nnoremap <C-S-P> :FZF<CR>

	let g:markdownfmt_autosave = 1
endif

set cm=blowfish2

if has('mouse')
	set mouse=a
endif

nnoremap <silent> <F9> :<C-U>set wrap!\|if &wrap \| echo "Word wrap ON" \| else \| echo "Word wrap OFF"\|endif<CR>
inoremap <silent> <F9> <C-O>:set wrap!<CR>
nnoremap <silent> <S-F9> :set cursorline!<CR>
nnoremap gV <C-Q>

set ts=4
set sw=4
set showcmd
set display=lastline
set noequalalways

set nu
set cin
set ai
set hidden
let g:seoul256_background = 234
sil! color seoul256

set hls is
set ignorecase smartcase

set nowrap
set linebreak

set so=5
set siso=20
set laststatus=2

function! AliasEnc(...)
	let isFenc = (a:0 > 0 && (a:1 == 'f' || a:1 == 'F'))
	let lenc = (isFenc ? &fenc : &enc)
	if lenc =~ "cp950"
		let lenc = "B5"
	elseif lenc =~ "cp936"
		let lenc = "GB"
	elseif lenc =~ "cp932"
		let lenc = "Jp"
	elseif lenc =~ "utf-8"
		let lenc = "U8"
	elseif lenc =~ "^$"
		let lenc = "-"
		if isFenc && &binary
			return "bin"
		endif
	endif
	if isFenc && &bomb
		return lenc."m"
	endif
	return lenc
endfunction

au BufRead,BufNewFile,BufFilePost,BufWritePost *			call CacheBufPara()
function! CacheBufPara()
	if !&ma || &buftype =='nofile'
		let b:FtimeStr = ''
		return
	endif
	let Ftime = getftime(expand('%:p'))
	let b:FtimeStr = (Ftime > 0 ? ' '.strftime('(%Y-%m-%d %H:%M:%S)',Ftime) : '')
	"let b:FPath = expand('%:p:~:h')
endfunction

function! GetCacheFTime()
	if !&ma || &buftype =='nofile'
		if !exists('b:FtimeStr')
			return ''
		endif
		return b:FtimeStr
	endif
	"let l:time = getftime(expand('%:p'))
	if !exists('b:FtimeStr')
		if expand('%:p') ==# '' || !&ma
			let b:FtimeStr = ''
		else
			let Ftime = getftime(expand('%:p'))
			let b:FtimeStr = (Ftime > 0 ? ' '.strftime('(%Y-%m-%d %H:%M:%S)',Ftime) : '')
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

let g:myFocus = 1
au WinEnter * let g:myFocus = winnr()

set noshowmode
set statusline=%(%#ModeMsg#%{GetMode()}%*\ %)%(\ %1*%r%*\ %)%(%Y\│%)%(%M\│%)\ %{expand('%')==expand('%:t')?'':'…/'}%t%<%{&key==''?'':'\ ['.&cm.']'}%{GetCacheFTime()}%=%k[0x%02B]\ [%{GetFF().','.AliasEnc().',f:'.AliasEnc('f')}]%{(&scb==1?'B':'').(&wrap==1?'W':'')}\ %-5.(%l,%c%V%)\ %P
set laststatus=2

set backspace=indent,eol,start
set complete-=i
set autochdir

if &term =~ "^xterm\\|rxvt"
	let &t_EI = "\e[1 q"
	let &t_SI = "\e[5 q"
	augroup myCmds
		au!
		autocmd VimEnter * silent !echo -ne "\e[2 q"
		autocmd VimLeave * silent !echo -ne "\e[6 q"
	augroup END
endif

