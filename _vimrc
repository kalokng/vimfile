"Plugin List
"#1506 LargeFile
"#1238 Mark

set guioptions-=T
set guioptions-=m
set guioptions+=b
"set guitablabel=%N\ %t

source $VIMRUNTIME/delmenu.vim
set langmenu=none
source $VIMRUNTIME/menu.vim

source $VIMRUNTIME/macros/matchit.vim
filetype plugin indent on

"php
let g:PHP_default_indenting = 1

"haskell
au BufEnter *.hs compiler ghc
let g:haddock_browser="C:\\Users\\Lok\\AppData\\Local\\Google\\Chrome\\Application\\chrome.exe"
let g:haddock_docdir="C:\\Program Files (x86)\\Haskell Platform\\2010.2.0.0\\doc\\html"

let g:zip_unzipcmd= "7z"

"map <F5> :syn sync fromstart<CR>
nnoremap <S-F5> zfaB
nnoremap <F5> "=strftime("%Y-%m-%d %H:%M:%S")<CR>p
inoremap <F5> =strftime("%Y-%m-%d %H:%M:%S")<CR>
cnoremap <F5> =strftime("%Y%m%d_%H%M%S")<CR>
nnoremap <F9> :set wrap!<CR>
inoremap <F9> <C-O>:set wrap!<CR>

set ts=4
set sw=4
set guifont=DotumChe:cHANGEUL
set guifont=DejaVu_Sans_Mono:h9,Consolas:h9,Bitstream_Vera_Sans_Mono:h8,Courier_New:h9
"set guifontset=-*-Consolas-medium-r-normal--9-*-*-*-c-*-*-*

syn on
let g:load_doxygen_syntax=1
"set fdm=syntax
"set nofen

set nu
set cin
set ai
set hidden
"set si
"set showmatch
"set cpoptions-=m

"se cursorline
hi LineNr guibg=LightGray guifg=Brown
hi CursorLine guibg=LightCyan
hi StatusLineNC	guibg=darkgrey guifg=white gui=none
"color default
"color desert
hi WarningMsg guifg=black guibg=green

set hls is
set ignorecase smartcase

set nowrap
"set wrap
set linebreak

set so=4

"let g:netrw_browse_split=3
let g:netrw_winsize=30
let g:netrw_liststyle= 3

function! AliasEncoding(flag)
	if a:flag =~ "cp950"
		return "Big5"
	elseif a:flag =~ "cp936"
		return "GB"
	elseif a:flag =~ "cp932"
		return "Japan"
	elseif a:flag =~ "^$"
		return "--"
	else
		return a:flag
	endif
endfunction

set statusline=%<%f\ %h%m%r\ (%{strftime(\"%H:%M\ %d/%m/%Y\",getftime(expand(\"%:p\")))})%=[%{&ff.','.AliasEncoding(&enc).','.AliasEncoding(&fenc)}]\ %-5.(%l,%c%V%)\ %P
set laststatus=2

set backspace=2

function! Comment()
	let save_cursor = getpos(".")
	let myline = getline(".")
	let mycol = matchend(myline, "\^[ \t]*")
	call setline(".", strpart(myline, 0, mycol) . "//" . strpart(myline, mycol))
	let save_cursor[1:2] += [0, 2]
	call setpos(".", save_cursor)
endfunction

function! Uncomment()
	let save_cursor = getpos(".")
	let myline = getline(".")
	let mycol = matchend(myline, "\^[ \t]*\/\/")
	if mycol != -1
		call setline(".", strpart(myline, 0, mycol - 2) . strpart(myline, mycol))
		let save_cursor[1:2] -= [0, 2]
	endif
	call setpos(".", save_cursor)
endfunction

function! Myfunc()
	let SearchStr = substitute(a:string, "/", "\/", "g")
	let SearchStr = substitute(SearchStr, "[[:return:]]", "\n", "g")
	echo SearchStr
	let @/='\V'.SearchStr
endfunction

function! DecToBin(dex)
	let l:result = ""
	let l:dex = a:dex
	while l:dex > 0
		let l:result = (l:dex % 2) . l:result
		let l:dex = l:dex / 2
	endwhile
	return l:result
endfunction

function! BinToDec(bin)
	if type(a:bin) == 0
		echoerr "Input must be string"
		return -1
	endif
	let l:result = 0
	let l:bin = matchstr(a:bin, "^[01]*")
	while strlen(l:bin) > 0
		let l:result = l:result * 2
		let l:result += l:bin[0]
		let l:bin = l:bin[1:]
	endwhile
	return l:result
endfunction

if has("multi_byte")
	set encoding=utf8
	"change load file encoding
	nnoremap Zj :e ++enc=japan ++bad=keep<CR>
	nnoremap Zs :e ++enc=cp936 ++bad=keep<CR>
	nnoremap Zt :e ++enc=cp950 ++bad=keep<CR>
	nnoremap Zu :e ++enc=utf-8 ++bad=keep<CR>
	nnoremap Zl :e ++enc=latin1 ++bad=keep<CR>
	nnoremap Zb :e ++bin<CR>
	nnoremap ZJ :e ++enc=japan ++bad=keep<CR>
	nnoremap ZS :e ++enc=cp936 ++bad=keep<CR>
	nnoremap ZT :e ++enc=cp950 ++bad=keep<CR>
	nnoremap ZU :e ++enc=utf-8 ++bad=keep<CR>
	nnoremap ZL :e ++enc=latin1 ++bad=keep<CR>
	nnoremap ZB :e ++nobin<CR>
	"change save file encoding
	nnoremap <C-p><C-j> :set fenc=japan<CR>
	nnoremap <C-p><C-s> :set fenc=cp936<CR>
	nnoremap <C-p><C-t> :set fenc=cp950<CR>
	nnoremap <C-p><C-u> :set fenc=utf-8<CR>
	nnoremap <C-p><C-l> :set fenc=latin1<CR>
	nnoremap <C-p><C-b> :set bin<CR>
	nnoremap <C-p><C-B> :set bin<CR>
	nnoremap <C-p>j :set fenc=japan<CR>
	nnoremap <C-p>s :set fenc=cp936<CR>
	nnoremap <C-p>t :set fenc=cp950<CR>
	nnoremap <C-p>u :set fenc=utf-8<CR>
	nnoremap <C-p>l :set fenc=latin1<CR>
	nnoremap <C-p>b :set nobin<CR>
	nnoremap <C-p>B :set nobin<CR>
	"change encoding
	nnoremap <C-H><C-j> :set enc=japan<CR>
	nnoremap <C-H><C-s> :set enc=cp936<CR>
	nnoremap <C-H><C-t> :set enc=cp950<CR>
	nnoremap <C-H><C-u> :set enc=utf-8<CR>
	nnoremap <C-H><C-l> :set enc=latin1<CR>
	nnoremap <C-H>j :set enc=japan<CR>
	nnoremap <C-H>s :set enc=cp936<CR>
	nnoremap <C-H>t :set enc=cp950<CR>
	nnoremap <C-H>u :set enc=utf-8<CR>
	nnoremap <C-H>l :set enc=latin1<CR>
else
	echoerr "Sorry, this version of (g)vim was not compiled with multi_byte"
endif

" CTRL-Tab is Next window
noremap <C-Tab> <C-W>w
inoremap <C-Tab> <C-O><C-W>w
cnoremap <C-Tab> <C-C><C-W>w
onoremap <C-Tab> <C-C><C-W>w

inoremap <C-U> <C-G>u<C-U>
inoremap <C-W> <C-G>u<C-W>

map <F6> :call Comment()<CR>
map <S-F6> :call Uncomment()<CR>
imap <F6> <C-O>:call Comment()<CR>
imap <S-F6> <C-O>:call Uncomment()<CR>

nmap <F7> :diffthis<CR>
nmap <F8> :diffoff<CR>

imap <C-S> <ESC>:w<CR>
nmap <C-S> :w<CR>
inoremap <C-V> <C-G>u<C-R><C-P>+
nnoremap <C-V> "+gp
cnoremap <C-V> <MiddleMouse>
vnoremap <C-V> "+p
nnoremap <C-C> "+y$
vnoremap <C-C> "+y
vnoremap <C-X> "+d

nnoremap Y y$
nnoremap y% :let @+=expand("%:p")<CR>

nmap <F2> :set scb<CR>
nmap <C-F2> :sil! explorer /e,=getcwd()<CR> /select,%<CR>
nmap <F3> :set noscb<CR>
nmap <F4> @@

nmap <C-N> :tab split<CR>

nnoremap <C-S-Left> vb
nnoremap <C-S-Right> ve
nnoremap <S-Left> vh
nnoremap <S-Right> vl
nnoremap <S-Up> vk
nnoremap <S-Down> vj
inoremap <S-Left> <C-O>vh
inoremap <S-Right> <C-O>vl
inoremap <S-Up> <C-O>vk
inoremap <S-Down> <C-O>vj
vnoremap <S-Left> h
vnoremap <S-Right> l
vnoremap <S-Up> k
vnoremap <S-Down> j

nnoremap <C-J> gj
nnoremap <C-k> gk

map [9 [(
map ]0 ])
nnoremap <silent> [) @=":call\ search(')', 'sWb')\n"<CR>
nnoremap <silent> ]( @=":call\ search('(', 'sW')\n"<CR>
nnoremap <silent> [0 @=":call\ search(')', 'sWb')\n"<CR>
nnoremap <silent> ]9 @=":call\ search('(', 'sW')\n"<CR>
nnoremap <silent> [} @=":call\ search('}', 'sWb')\n"<CR>
nnoremap <silent> ]{ @=":call\ search('{', 'sW')\n"<CR>

nnoremap <silent> <M-;> ;
nnoremap <silent> <M-,> ,
vnoremap <silent> <M-;> ;
vnoremap <silent> <M-,> ,
nnoremap <silent> ; @=':call search(''[A-Z]\+\\|_\+\zs[A-Z]*'', '''', line(''.''))'."\n"<CR>
nnoremap <silent> , @=':call search(''[A-Z]\+\\|_\+\zs[A-Z]*'', ''b'', line(''.''))'."\n"<CR>
vnoremap <silent> ; <ESC>@=':call search(''[A-Z]\+\\|_\+\zs[A-Z]*'', '''', line(''.''))'."\n"<CR>mugv`u
vnoremap <silent> , <ESC>@=':call search(''[A-Z]\+\\|_\+\zs[A-Z]*'', ''b'', line(''.''))'."\n"<CR>mugv`u

vnoremap <M-/> <Esc>/\%><C-R>=line("'<")-1<CR>l\%<<C-R>=line("'>")+1<CR>l
vnoremap <M-?> <Esc>?\%><C-R>=line("'<")-1<CR>l\%<<C-R>=line("'>")+1<CR>l

"nmap <F11> :set fdm=sync
"vmap { @=":call\ search('^[[:blank:]]*$', 'Wb')\n"<CR>
"vmap } @=":call\ search('^[[:blank:]]*$', 'W')\n"<CR>
"nmap { @=":call\ search('^[[:blank:]]*$', 'Wb')\n"<CR>
"nmap } @=":call\ search('^[[:blank:]]*$', 'W')\n"<CR>

augroup myau
	au!
	au BufEnter * lcd %:p:h
	"au BufEnter * set nocul
	"au BufLeave * set cul
	"autocmd InsertLeave * hi CursorLine guibg=LightCyan
	"autocmd InsertEnter * hi CursorLine guibg=LightGray
augroup END

nmap <F1> :call Auto_Highlight_Cword()<CR>
vmap <F1> :call setreg("/", GetSelectionEscaped("enV"))<CR>
nmap <C-Space> :call Auto_Highlight_Cword()<CR>
vmap <C-Space> :call setreg("/", GetSelectionEscaped("enV"))<CR>

nnoremap <M-/> :vimgrep /
cnoremap <M-/> <SPACE><C-R>=fnameescape(getcwd())<CR>
cnoremap <M-?> <SPACE><C-R>=fnameescape(expand("%:p:h"))<CR>
nmap <M-n> :cn<CR>
nmap <M-N> :cN<CR>

"fullscreen
noremap <M-]> :set lines=999 columns=999<CR>
"normal
noremap <M-[> :set lines=24 columns=80<CR>
"vertical maximize
noremap <M-\> :set lines=999<CR>

inoremap <S-F7> <C-O>:set spell!<CR>
inoremap <S-F8> <C-O>:set list!<CR>
nnoremap <S-F7> :set spell!<CR>
nnoremap <S-F8> :set list!<CR>
nnoremap <M-F8> :let @z=@/<CR>:%s/\s\+$//<CR><C-O>:let @/=@z<CR>

function! LineCount(...)
	if (a:0 == 0)
		return line('$')
	endif
	let linec = 0
	let curMore = &more
	let curHid = &hidden
	set nomore
	set nohidden
	exec "args " . a:1
	argdo let linec=linec+line('$')
	if (curMore == 1)
		set more
	endif
	if (curHid == 1)
		set hidden
	endif
	return linec
endfunction

function! Auto_Highlight_Cword()
  set hls
  exe "let @/='\\<".expand("<cword>")."\\>'"
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

nmap <C-PageDown> G:sleep 1000m<CR>:call Auto_Scroll_Down()<CR><C-PageDown>
function! Auto_Scroll_Down()
	try
		e
	catch
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

function! GuiTabLabel()
  let label = ''
  let bufnrlist = tabpagebuflist(v:lnum)

  " Add '*' if one of the buffers in the tab page is modified
  for bufnr in bufnrlist
    if getbufvar(bufnr, "&modified")
      let label = '*'
      break
    endif
  endfor

  " Append the number of windows in the tab page if more than one
  let wincount = tabpagewinnr(v:lnum, '$')
  if wincount > 1
	let label .= ' ' . wincount
  endif

  " Append the buffer name
  return label
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

set guitablabel=%N:%{GuiTabLabel()}\ %t

set lcs=tab:¦¨,eol:¶,nbsp:§,trail:»

syn match trailingWhite display "[[:space:]]\+$"
hi link trailingWhite Error

"set spell spelllang=en
set spellsuggest=double

"utl.vba
nnoremap <C-LeftMouse> <LeftMouse>:Utl ol<CR>

"mark.vba
highlight def MarkWord1   ctermbg=Cyan         ctermfg=Black  guibg=#FF7FBF    guifg=Black
highlight def MarkWord2   ctermbg=Green        ctermfg=Black  guibg=#BFFF7F    guifg=Black
highlight def MarkWord3   ctermbg=Yellow       ctermfg=Black  guibg=#7FBFFF    guifg=Black
highlight def MarkWord4   ctermbg=Red          ctermfg=Black  guibg=#FFBFBF    guifg=Black
highlight def MarkWord5   ctermbg=Magenta      ctermfg=Black  guibg=#BFFFBF    guifg=Black
highlight def MarkWord6   ctermbg=Blue         ctermfg=Black  guibg=#BFBFFF    guifg=Black
highlight def MarkWord7   ctermbg=DarkCyan     ctermfg=Black  guibg=#FFFFBF    guifg=Black
highlight def MarkWord8   ctermbg=DarkGreen    ctermfg=Black  guibg=#BFFFFF    guifg=Black
highlight def MarkWord9   ctermbg=DarkYellow   ctermfg=Black  guibg=#FFBFFF    guifg=Black
highlight def MarkWord10  ctermbg=DarkRed      ctermfg=Black  guibg=#FFBF7F    guifg=Black
highlight def MarkWord11  ctermbg=DarkMagenta  ctermfg=Black  guibg=#7FFFBF    guifg=Black
highlight def MarkWord12  ctermbg=DarkBlue     ctermfg=Black  guibg=#BF7FFF    guifg=Black
highlight def MarkWord13  ctermbg=Grey         ctermfg=Black  guibg=#BF7F7F    guifg=Black
highlight def MarkWord14  ctermbg=LightRed     ctermfg=Black  guibg=#7FBF7F    guifg=Black
highlight def MarkWord15  ctermbg=LightYellow  ctermfg=Black  guibg=#7F7FBF    guifg=Black

"DoxygenToolkit
let g:DoxygenToolkit_compactOneLineDoc = ""
let g:DoxygenToolkit_briefTag_pre = ""

"LargeFile
:let g:LargeFile=50

let Tlist_Ctags_Cmd='c:\luke\ctags58\ctags.exe'
let g:easytags_cmd='c:\luke\ctags58\ctags.exe'
let g:easytags_on_cursorhold=0

"blockinsert
vmap <leader>i  <plug>blockinsert-i
vmap <leader>a  <plug>blockinsert-a
vmap <leader>qi <plug>blockinsert-qi
vmap <leader>qa <plug>blockinsert-qa

nmap <leader>i  <plug>blockinsert-i
nmap <leader>a  <plug>blockinsert-a
nmap <leader>qi <plug>blockinsert-qi
nmap <leader>qa <plug>blockinsert-qa

vmap <leader>[]  <plug>blockinsert-b
vmap <leader>[[  <plug>blockinsert-ub
vmap <leader>]]  <plug>blockinsert-ub
vmap <leader>q[] <plug>blockinsert-qb
vmap <leader>q[[ <plug>blockinsert-uqb
vmap <leader>q]] <plug>blockinsert-uqb

nmap <leader>[]  <plug>blockinsert-b
nmap <leader>[[  <plug>blockinsert-ub
nmap <leader>]]  <plug>blockinsert-ub
nmap <leader>q[] <plug>blockinsert-qb
nmap <leader>q[[ <plug>blockinsert-uqb
nmap <leader>q]] <plug>blockinsert-uqb
"blockinsert

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

map <C-F12> :!c:\luke\ctags58\ctags -R --c++-kinds=+p --fields=+iaS --extra=+q .<CR>

set path+=C:\cvsproject\GGAG\Source\Common\CPP\Code\Common

:dig sS 9828
:dig sH 9829
:dig sC 9831
:dig sD 9830

set noswf

au BufRead,BufNewFile *.wiki			setfiletype wiki
au BufRead,BufNewFile *.wikipedia.org*	setfiletype wiki

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

"dw:call setline(2, getline(2).printf("%c", 0x"))
"%s,\v\<([^<>]+)\>[^<>]+\</\1\>|\<[^<>]+/\>,&\r,g
"%s,\v\<([^<>]+)\>((\<.{-}\>)|)\</\1\>,<\1>\r\2</\1>\r,g
"call setline('$', getline('$') . printf("%c", 0x
"%s,<[^>]\+>\zs\ze<[^>]\+>,\r,g
"g//let b:a=b:a+1|exe "normal 0i".(-1+b:a)

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

"inoremap <TAB> <C-R>=InsertTabWrapper("forward")<CR>
"inoremap <S-TAB> <C-R>=InsertTabWrapper("backward")<CR>

"C:\Program Files\vim\vim71\gvim.exe
"--servername gmain --remote-silent +$(CurLine) +"normal zz" $(FileName)$(FileExt)
"(none)
"
"Arguments: --servername gmain --remote-silent +"call cursor($(CurLine),$(CurCol))" +"normal zz" "$(FilePath)"
"
"    ----- For Replacement in Objective C -----
"set nomore
"^-\s*(id)\s*init\>\_.\{-}\zs.*\(NSLog([^)]*);$\n\)\{1}\ze\_.*return self;
"argdo %s/^-\s*(id)\s*init\>\_.\{-}\zs.*\(NSLog([^)]*);$\n\)\{1}\ze\_.*return self;//e | update
"argdo %s/^-\s*(id)\s*init\>\_.\{-}\zs\ze.*return self;/NSLog(@"Object init : %@", self);\r/e | update
"argdo g/^NSL/exe "normal ==" | update

"Search no XXX
"^.*\(XXX.*\)\@<!$
