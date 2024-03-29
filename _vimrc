"Plugin List
"#1506 LargeFile
"#1238 Mark

set nocp

sil! call plug#begin()
if exists('*plug#begin')
	Plug 'tpope/vim-sensible'
	Plug 'fatih/vim-go', { 'tag': '*', 'do': ':GoInstallBinaries' }
	"Plug 'govim/govim'
	Plug 'junegunn/vim-easy-align'
	Plug 'jreybert/vimagit'
	Plug 'junegunn/seoul256.vim'
	Plug 'mbbill/undotree'
	Plug 'ctrlpvim/ctrlp.vim'
	Plug 'justinmk/vim-sneak'
	Plug 'rust-lang/rust.vim'
	Plug 'PProvost/vim-ps1', { 'for': 'ps1' }
	Plug 'inkarkat/vim-ingo-library'
	Plug 'inkarkat/vim-mark'
	Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
	Plug '~/vimfiles/plugged/after'
	call plug#end()

	let g:ctrlp_cmd = 'CtrlPMRU'
	let g:ctrlp_types = ['mru', 'fil', 'buf']

	nnoremap <C-S-P> :FZF<CR>

	let g:mwExclusionPredicates = []
endif

set noautoread

let g:sneak#label = 1
map f <Plug>Sneak_f
map t <Plug>Sneak_t
map F <Plug>Sneak_F
map T <Plug>Sneak_T

vmap <Enter> <Plug>(LiveEasyAlign)

nmap <Space>r <Plug>MarkRegex
let g:mwMaxMatchPriority = -10
let g:mwDirectGroupJumpMappingNum = 0

source $VIMRUNTIME/macros/matchit.vim
filetype plugin indent on
"set shellslash
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

if has("patch-8.1.1904")
	set completeopt+=popup
	set completepopup=align:menu,border:off,highlight:Pmenu
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

"map <F5> :syn sync fromstart<CR>
nnoremap <silent> <S-F5> zfaB
nnoremap <silent> <F5> "=strftime("%Y-%m-%d %H:%M:%S")<CR>p
nnoremap <silent> <M-F5> "=strftime("%Y%m%d%H%M%S")<CR>p
inoremap <silent> <F5> <C-R>=strftime("%Y-%m-%d %H:%M:%S")<CR>
inoremap <silent> <S-F5> <C-R>=strftime("%Y-%m-%d")<CR>
inoremap <silent> <M-F5> <C-R>=strftime("%Y%m%d%H%M%S")<CR>
cnoremap <F5> <C-R>=strftime("%Y%m%d_%H%M%S")<CR>
cnoremap <S-F5> <C-R>=strftime("%Y%m%d")<CR>
nnoremap <silent> <F9> :<C-U>set wrap!\|if &wrap \| echo "Word wrap ON" \| else \| echo "Word wrap OFF"\|endif<CR>
inoremap <silent> <F9> <C-O>:set wrap!<CR>
nnoremap <silent> <S-F9> :set cursorline!<CR>

set ts=4
set sw=4
"set nolbr
set showcmd
set display=lastline
set noea

set noswf
"set dir=C:\temp\swap

syn on
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

set so=4
set siso=3

"let g:netrw_browse_split=3
let g:netrw_winsize=30
let g:netrw_liststyle= 1

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
		let lenc = "--"
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
	let Ftime = getftime(expand('%:p'))
	let b:FtimeStr = (Ftime > 0 ? ' '.strftime('(%Y-%m-%d %H:%M:%S)',Ftime) : '')
	"let b:FPath = expand('%:p:~:h')
endfunction

function! GetCacheFTime()
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

"set titlestring=%t%(\ %M%)%(\ %{GetCacheFTime()}%)%<%(\ (%{GetCachePath()})%)%a%(\ -\ %{v:servername}%)
"set statusline=%(\ %1*%r%*\ %)%(%Y\|%)\ %<%{getcwd()==expand('%:p:h')?'':'.../'}%t\ %m%{GetCacheFTime()}%=%k[%{GetFF().','.AliasEnc().','.AliasEnc('f')}]%{(&scb==1?'B':'').(&wrap==1?'W':'')}\ [0x%02B]\ %-5.(%l,%c%V%)\ %P
"set statusline=%(\ %1*%r%*\ %)%(%Y\|%)%<\ %f%(\ %m%)%{GetCacheFTime()}%=%k[%{GetFF().','.AliasEnc().','.AliasEnc('f')}]%{(&scb==1?'B':'').(&wrap==1?'W':'')}\ [0x%02B]\ %-5.(%l,%c%V%)\ %P
set noshowmode
set statusline=%(%#ModeMsg#%{GetMode()}%*\ %)%(\ %1*%r%*\ %)%(%Y\|%)%(%M\|%)\ %{expand('%')==expand('%:t')?'':'…/'}%t%<%{&key==''?'':'\ ['.&cm.']'}%{GetCacheFTime()}%=%k[0x%02B]\ [%{GetFF().','.AliasEnc().','.AliasEnc('f')}]%{(&scb==1?'B':'').(&wrap==1?'W':'')}\ %-5.(%l,%c%V%)\ %P
set laststatus=2

set backspace=2

function! Comment()
	let save_col = col(".")
	let myline = getline(".")
	"let mycol = matchend(myline, "\^[ \t]*")
	"call setline(".", strpart(myline, 0, mycol) . "//" . strpart(myline, mycol))
	call setline(".", "//" . myline)
	call cursor(0, save_col+2)
endfunction

function! Uncomment()
	let save_col = col(".")
	let myline = getline(".")
	let mycol = matchend(myline, "\^[ \t]*\/\/")
	if mycol != -1
		call setline(".", strpart(myline, 0, mycol - 2) . strpart(myline, mycol))
		let save_col -= 2
	endif
	call cursor(0, save_col)
endfunction

function! Myfunc()
	let SearchStr = substitute(a:string, "/", "\/", "g")
	let SearchStr = substitute(SearchStr, "[[:return:]]", "\n", "g")
	echo SearchStr
	let @/='\V'.SearchStr
endfunction

function! Nr2Bin(num,...)
	let l:result = ""
	if type(a:num) == type(0.0)
		let l:num = float2nr(a:num)
	else
		let l:num = a:num
	endif
	while l:num > 0
		let l:result = (l:num % 2) . l:result
		let l:num = l:num / 2
	endwhile
	if (a:0 > 0 && strlen(l:result) < a:1)
		let l:result=printf('%0'.(a:1-strlen(l:result)).'d',0).l:result
	endif
	return l:result
endfunction

function! Bin2Nr(bin)
	if type(a:bin) == 0
		echoerr "Input must be string"
		return -1
	endif
	let l:result = 0
	let l:bin = matchstr(a:bin, "^[01]*")
	while strlen(l:bin) > 0
		let l:result = l:result * 2
		let l:result = l:result + l:bin[0]
		let l:bin = l:bin[1:]
	endwhile
	return l:result
endfunction

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
	nnoremap <silent> <C-M><C-j> :set fenc=japan<CR>
	nnoremap <silent> <C-M><C-s> :set fenc=cp936<CR>
	nnoremap <silent> <C-M><C-t> :set fenc=cp950<CR>
	nnoremap <silent> <C-M><C-u> :set fenc=utf-8<CR>
	nnoremap <silent> <C-M><C-l> :set fenc=latin1<CR>
	nnoremap <silent> <C-M><C-b> :set bin<CR>
	nnoremap <silent> <C-M><C-B> :set bin<CR>
	nnoremap <silent> <C-M><C-m> :set bomb<CR>
	nnoremap <silent> <C-M><C-M> :set bomb<CR>
	nnoremap <silent> <C-M>j :set fenc=japan<CR>
	nnoremap <silent> <C-M>s :set fenc=cp936<CR>
	nnoremap <silent> <C-M>t :set fenc=cp950<CR>
	nnoremap <silent> <C-M>u :set fenc=utf-8<CR>
	nnoremap <silent> <C-M>l :set fenc=latin1<CR>
	nnoremap <silent> <C-M>b :set nobin<CR>
	nnoremap <silent> <C-M>B :set nobin<CR>
	nnoremap <silent> <C-M>m :set nobomb<CR>
	nnoremap <silent> <C-M>M :set nobomb<CR>
	"change encoding
	nnoremap <silent> <C-H><C-j> :set enc=japan<CR>
	nnoremap <silent> <C-H><C-s> :set enc=cp936<CR>
	nnoremap <silent> <C-H><C-t> :set enc=cp950<CR>
	nnoremap <silent> <C-H><C-u> :set enc=utf-8<CR>
	nnoremap <silent> <C-H><C-l> :set enc=latin1<CR>
	nnoremap <silent> <C-H>j :set enc=japan<CR>
	nnoremap <silent> <C-H>s :set enc=cp936<CR>
	nnoremap <silent> <C-H>t :set enc=cp950<CR>
	nnoremap <silent> <C-H>u :set enc=utf-8<CR>
	nnoremap <silent> <C-H>l :set enc=latin1<CR>
else
	echoerr "Sorry, this version of (g)vim was not compiled with multi_byte"
endif

" CTRL-Tab is Next window
noremap <silent> <C-Tab> <C-W>w
inoremap <silent> <C-Tab> <C-O><C-W>w
cnoremap <silent> <C-Tab> <C-C><C-W>w
onoremap <silent> <C-Tab> <C-C><C-W>w
"noremap <Tab> <C-W>w
noremap <silent> <S-Tab> <C-W>w

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

map <silent> <F6> :call Comment()<CR>
map <silent> <S-F6> :call Uncomment()<CR>
imap <silent> <F6> <C-O>:call Comment()<CR>
imap <silent> <S-F6> <C-O>:call Uncomment()<CR>

nmap <silent> <F7> :if &diff \| diffoff \| else \| diffthis \| endif<CR>

if has("windows")
	function! <SID>startTerminal(name)
		let namemap               = {}
		let namemap["bash"]       = '"git bash"'
		let namemap["cmd"]        = '"Command Prompt"'
		let namemap["powershell"] = '"Windows PowerShell"'
		try
			sil exec "!start wt -d ".expand("%:p:h")." -p ".namemap[a:name]
		catch /\<E371\>/
			sil exec "!start ".a:name
		endtry
	endfunction
	command! Bash :call <SID>startTerminal("bash")
	command! Cmd :call <SID>startTerminal("cmd")
	command! Powershell :call <SID>startTerminal("powershell")
	if has("win64")
		command! Term :term C:\Windows\system32\bash.exe
	elseif has("win32")
		command! Term :term C:\Windows\sysnative\bash.exe
	endif
endif

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
nmap <silent> <C-F2> :!start explorer <c-r>=(expand('%')!=''?'/select,'.expand('%:p'):getcwd())<CR><CR>
nmap <silent> <F4> @@

nnoremap <silent> <C-W><C-^> :vs #<CR>
nnoremap <silent> <M-6> :call SwapC('e ')<CR>
nnoremap <silent> <C-W><M-6> :call SwapC('vs ')<CR>
function! SwapC(cmd)
	if &ft =~ 'cpp'
		if expand('%:p:e') =~ 'cpp'
			exe a:cmd . fnameescape(expand('%:p:r').'.h')
		elseif expand('%:p:e') =~ 'h'
			exe a:cmd . fnameescape(expand('%:p:r').'.cpp')
		endif
	elseif &ft =~ 'c'
		if expand('%:p:e') =~ 'c'
			exe a:cmd . fnameescape(expand('%:p:r').'.h')
		elseif expand('%:p:e') =~ 'h'
			exe a:cmd . fnameescape(expand('%:p:r').'.c')
		endif
	endif
endfunction

nnoremap <silent> <C-N> :tab split<CR>

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

"nnoremap <silent> <M-;> ;
"nnoremap <silent> <M-,> ,
"vnoremap <silent> <M-;> ;
"vnoremap <silent> <M-,> ,
nnoremap <silent> <M-;> @=':call search(''\u\+\\|_\+\zs\u*'', '''', line(''.''))'."\n"<CR>1<ESC>
nnoremap <silent> <M-,> @=':call search(''\u\+\\|_\+\zs\u*'', ''b'', line(''.''))'."\n"<CR>1<ESC>
"vnoremap <silent> ; <ESC>@=':call search(''\u\+\\|_\+\zs\u*'', '''', line(''.''))'."\n"<CR>mugv`u
"vnoremap <silent> , <ESC>@=':call search(''\u\+\\|_\+\zs\u*'', ''b'', line(''.''))'."\n"<CR>mugv`u
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
"augroup myau
"	au!
"	au BufEnter * lcd %:p:h
"	"au BufEnter * set nocul
"	"au BufLeave * set cul
"	"autocmd InsertLeave * hi CursorLine guibg=LightCyan
"	"autocmd InsertEnter * hi CursorLine guibg=LightGray
"augroup END

color industry

if &term =~ "^xterm\\|rxvt\\|win32"
	let &t_EI="\e[1 q"
	let &t_SI="\e[5 q"

	augroup myCmds
		au!
		autocmd VimEnter * silent !echo -ne "\e[1 q"
		autocmd VimLeave * silent !echo -ne "\e[6 q"
	augroup END

	if &term =~ "^xterm-256\\|win32"
		let g:seoul256_background = 234
		sil! color seoul256
	endif
endif

map <silent> Q gq
nnoremap <silent> <F1> :call Auto_Highlight_Cword()\|set hls<CR>
vnoremap <silent> <F1> :call SelectionHighlight()<CR>
nnoremap <silent> <C-Space> :call Auto_Highlight_Cword()\|set hls<CR>
vnoremap <silent> <C-Space> :call SelectionHighlight()<CR>

function! SelectionHighlight()
	let word = GetSelectionEscaped("enV")
	call histadd('/', word)
	call setreg('/', word)
endfunction

"nmap <silent> <F12> :exe '0,$!"'.$VIMRUNTIME.'\tidy" -q -i -xml --char-encoding utf8 --tab-size 4 -f '.$HOME.'\tidyError.txt'<CR>:cfile $HOME\tidyError.txt<CR>
"vmap <silent> <F12> :<C-U>exe '''<,''>!"'.$VIMRUNTIME.'\tidy" -q -i -xml --char-encoding utf8 --tab-size 4 -f '.$HOME.'\tidyError.txt'<CR>:cfile $HOME\tidyError.txt<CR>
nnoremap <F12> :UndotreeToggle<CR>

if has("persistent_undo")
	set undodir=~/.undodir/
	set undofile
endif

nnoremap <M-/> :vimgrep /
nnoremap <M-?> :1vimgrep /
cnoremap <M-/> <SPACE><C-R>=fnameescape(getcwd())<CR>/
cnoremap <M-?> <SPACE><C-R>=fnameescape(expand("%:p:h"))<CR>/
cnoremap <M-5> <SPACE><C-R>=fnameescape(expand('%:p'))<CR>
inoremap <M-/> <C-R>=fnameescape(expand("%:p:t"))<CR>
nmap <silent> <M-n> :cn<CR>
nmap <silent> <M-N> :cN<CR>
nnoremap m/ :lad expand('%').':'.line('.').':'.getline('.')<CR>
cnoremap <C-R>^ <C-R>=fnameescape(expand('%:p:h'))<CR>/
inoremap <C-R>^ <C-R>=expand('%:p:h')<CR>/
cnoremap <C-R><C-L> <C-R>=getline('.')<CR>

inoremap <silent> <S-F7> <C-O>:set spell!<CR>
inoremap <silent> <F8> <C-O>:set list!<CR>
nnoremap <silent> <S-F7> :set spell!<CR>
nnoremap <silent> <F8> :set list!<CR>
nnoremap <silent> <M-F8> :let @z=@/<CR>:%s/\s\+$//<CR><C-O>:let @/=@z<CR>

function! LineCount(...)
	if (a:0 == 0)
		return line('$')
	endif
	let l:curFile = expand('%:p')
	let l:linec = 0
	let l:curMore = &more
	let l:curHid = &hidden
	set nomore
	set nohidden
	exec "args " . a:1
	argdo let l:linec=l:linec+line('$')
	if (curMore == 1)
		set more
	endif
	if (curHid == 1)
		set hidden
	endif
	exe "e ".fnameescape(l:curFile)
	return l:linec
endfunction

function! Auto_Highlight_Cword()
	let word="\\<".expand("<cword>")."\\>"
	call histadd('/', word)
	"exe "let @/='\\<".expand("<cword>")."\\>'"
	let @/=word
endfunction

function! Auto_Highlight_Toggle()
  if exists("#CursorHold#*")
	au! CursorHold *
	let @/=''
  else
	set hlsearch
	set updatetime=500
	au! CursorHold * nested call Auto_Highlight_Cword()
  endif
endfunction

"nmap <C-PageDown> G:sleep 1000m<CR>:call Auto_Scroll_Down()<CR><C-PageDown>
command! -nargs=? AutoScroll :call Auto_Scroll_Down('<args>')
function! Auto_Scroll_Down(time)
	let l:time = str2nr(a:time)
	if l:time < 1
		let l:time = 1
	endif
	keepjumps normal G
	let l:line=line('$')
	e
	if l:line != line('$')
		keepjumps normal VG
	endif
	let l:prevUndoLvl=&undolevels
	" no undo for refreshing
	set undolevels=-1
	try
		while 1
			redraw
			exe 'sleep '.l:time
			let l:line=line('$')
			e
			if l:line != line('$')
				keepjumps normal VG
			endif
		endwhile
	catch
		let &undolevels=l:prevUndoLvl
		return
	endtry
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

"syn match trailingWhite display "[[:space:]]\+$"
"hi link trailingWhite WarningMsg
"highlight def TrailingWhite   ctermbg=DarkRed		   ctermfg=Black  guibg=#BFFFFF    guifg=Black

"set spell spelllang=en
set spellsuggest=double

"utl.vba
"nnoremap <silent> <C-LeftMouse> <LeftMouse>:Utl ol<CR>

"DoxygenToolkit
let g:DoxygenToolkit_compactOneLineDoc = ""
let g:DoxygenToolkit_briefTag_pre = ""

"LargeFile
:let g:LargeFile=50

let Tlist_Ctags_Cmd='c:\luke\ctags58\ctags.exe'
let g:easytags_cmd='c:\luke\ctags58\ctags.exe'
let g:easytags_on_cursorhold=0

""blockinsert
"vmap <leader>i	<plug>blockinsert-i
"vmap <leader>a	<plug>blockinsert-a
"vmap <leader>qi <plug>blockinsert-qi
"vmap <leader>qa <plug>blockinsert-qa
"
"nmap <leader>i	<plug>blockinsert-i
"nmap <leader>a	<plug>blockinsert-a
"nmap <leader>qi <plug>blockinsert-qi
"nmap <leader>qa <plug>blockinsert-qa
"
"vmap <leader>[]  <plug>blockinsert-b
"vmap <leader>[[  <plug>blockinsert-ub
"vmap <leader>]]  <plug>blockinsert-ub
"vmap <leader>q[] <plug>blockinsert-qb
"vmap <leader>q[[ <plug>blockinsert-uqb
"vmap <leader>q]] <plug>blockinsert-uqb
"
"nmap <leader>[]  <plug>blockinsert-b
"nmap <leader>[[  <plug>blockinsert-ub
"nmap <leader>]]  <plug>blockinsert-ub
"nmap <leader>q[] <plug>blockinsert-qb
"nmap <leader>q[[ <plug>blockinsert-uqb
"nmap <leader>q]] <plug>blockinsert-uqb
""blockinsert

let g:user_zen_settings = {
\  'php' : {
\    'extends' : 'html',
\    'filters' : 'c',
\  },
\  'xml' : {
\    'extends' : 'html',
\  },
\  'haml' : {
\    'extends' : 'html',
\  },
\}

nnoremap <silent> <C-F11> :TlistToggle<CR>

"map <C-F12> :!c:\luke\ctags58\ctags -R --c++-kinds=+p --fields=+iaS --extra=+q .<CR>

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

au BufRead,BufNewFile *.wiki			setfiletype wiki
au BufRead,BufNewFile *.wikipedia.org*	setfiletype wiki

let g:netrw_cygwin = 0
let g:netrw_silent = 1
let g:netrw_scp_cmd = 'c:\"Program Files (x86)"\PuTTY\pscp.exe -q'
let g:netrw_sftp_cmd= 'c:\"Program Files (x86)"\PuTTY\psftp.exe'

if exists(':TOhtml') == 2
	function! MyConvert2HTML(line1, line2)
		"add the matchadd to syntax highlight
		let l:mList = getmatches()
		for l:mi in l:mList
			exe "syntax match ".l:mi['group']." /".escape(l:mi['pattern'],'/')."/ containedin=.*"
		endfor
		"[{'group': 'MarkWord1', 'pattern': '\c\<highlight\>', 'priority': -24, 'id': 4}]
		return tohtml#Convert2HTML(a:line1, a:line2)
	endfunction
	command! -nargs=0 -range=% TOhtml :call MyConvert2HTML(<line1>, <line2>)
	"command! -nargs=0 TOhtml :call MyConvert2HTML(<line1>, <line2>)
endif

"set diffexpr=MyDiff()
"function! MyDiff()
"	let opt=""
"	if &diffopt =~ "icase"
"		let opt = opt . "-i "
"	endif
"	if &diffopt =~ "iwhite"
"		let opt = opt. "-b "
"	endif
"	silent execute '!""D:\\vim\\vim73\\diff"" -a '.opt.v:fname_in.'	'.v:fname_new.' > '.v:fname_out
"endfunction

set directory^=$HOME/tmp
set backupdir^=$HOME/tmp

"set path+="C:\\Program\ Files\ (x86)\\boost\\boost_1_47"

command! -nargs=? -complete=file Admin :exec "silent !elevate ".$VIMRUNTIME."\\gvim <args>"

"==== elevate.js START HERE ====
"// elevate.js -- runs target command line elevated
"if (WScript.Arguments.Length >= 1) {
"    Application = WScript.Arguments(0);
"    Arguments = "";
"    for (Index = 1; Index < WScript.Arguments.Length; Index += 1) {
"        if (Index > 1) {
"            Arguments += " ";
"        }
"        Arguments += WScript.Arguments(Index);
"    }
"    new ActiveXObject("Shell.Application").ShellExecute(Application, Arguments, "", "runas");
"} else {
"    WScript.Echo("Usage:");
"    WScript.Echo("elevate Application Arguments");
"}
"==== elevate.js END HERE ====
"Save a file with sudo under POSIX system
"cnoremap w!! w !sudo tee %
" Go to last file(s) if invoked without arguments.
"autocmd VimLeave * nested if (!isdirectory($HOME . "/.vim")) |
"	\ call mkdir($HOME . "/.vim") |
"	\ endif |
"	\ execute "mksession! " . $HOME . "/.vim/Session.vim" |
"
"autocmd VimEnter * nested if argc() == 0 && filereadable($HOME . "/.vim/Session.vim") |
"	\ execute "call rename('".$HOME . "/.vim/Session.vim','" . $HOME . "/.vim/Session.vim.bak')" |
"	\ execute "source " . $HOME . "/.vim/Session.vim.bak" |
"	\ execute "call delete('"$HOME . "/.vim/Session.vim')"
"
"dw:call setline(2, getline(2).printf("%c", 0x"))
"%s,\v\<([^<>]+)\>[^<>]+\</\1\>|\<[^<>]+/\>,&\r,g
"%s,\v\<([^<>]+)\>((\<.{-}\>)|)\</\1\>,<\1>\r\2</\1>\r,g
"call setline('$', getline('$') . printf("%c", 0x
"%s,<[^>]\+>\zs\ze<[^>]\+>,\r,g
"g//let b:a=b:a+1|exe "normal 0i".(-1+b:a)
"
"function! InsertTabWrapper(direction)
  "let col = col('.') - 1
  "if !col || getline('.')[col - 1] !~ '\k'
	"return "\<tab>"
  "elseif "backward" == a:direction
	"return "\<c-p>"
  "else
	"return "\<c-n>"
  "endif
"endfunction
"
"inoremap <TAB> <C-R>=InsertTabWrapper("forward")<CR>
"inoremap <S-TAB> <C-R>=InsertTabWrapper("backward")<CR>
"
"C:\Program Files\vim\vim71\gvim.exe
"--servername gmain --remote-silent +$(CurLine) +"normal zz" $(FileName)$(FileExt)
"(none)
"
"Arguments: --servername gmain --remote-silent +"call cursor($(CurLine),$(CurCol))" +"normal zz" "$(FilePath)"
"
"	 ----- For Replacement in Objective C -----
"set nomore
"^-\s*(id)\s*init\>\_.\{-}\zs.*\(NSLog([^)]*);$\n\)\{1}\ze\_.*return self;
"argdo %s/^-\s*(id)\s*init\>\_.\{-}\zs.*\(NSLog([^)]*);$\n\)\{1}\ze\_.*return self;//e | update
"argdo %s/^-\s*(id)\s*init\>\_.\{-}\zs\ze.*return self;/NSLog(@"Object init : %@", self);\r/e | update
"argdo g/^NSL/exe "normal ==" | update
"
"Search no XXX
"^.*\(XXX.*\)\@<!$
"go no gui
"--ldflags -H=windowsgui
