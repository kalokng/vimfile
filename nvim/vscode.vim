"neovide settings

sil! call plug#begin()
if exists('*plug#begin')
	Plug 'tpope/vim-sensible'
	Plug 'junegunn/vim-easy-align'
	Plug 'justinmk/vim-sneak'
	Plug 'PProvost/vim-ps1', { 'for': 'ps1' }
	Plug 'inkarkat/vim-ingo-library'
	Plug 'inkarkat/vim-mark'
	call plug#end()

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

	function! Check_back_space() abort
		let col = col('.') - 1
		return !col || getline('.')[col - 1] =~# '\s'
	endfunction

endif

set noswf
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

map <MiddleMouse> <NOP>
inoremap <C-V> <C-G>u<C-R>+
nnoremap <C-V> "+gp
nnoremap <silent> <C-C> "+y$
vnoremap <silent> <C-C> "+y

nnoremap <silent> Y y$
nnoremap <silent> y% :let @+=expand('%:p')<CR>:echo "copied '".@+."'"<CR>
nnoremap <silent> y<C-R>% :let @+=expand('%:t')<CR>:echo "copied '".@+."'"<CR>
nnoremap <silent> y<C-R><C-R>% :let @+=@%<CR>:echo "copied '".@+."'"<CR>

nnoremap <silent> <C-W><C-^> :vs #<CR>

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

if has("persistent_undo")
	set undodir=~/.undodir/
	set undofile
endif

"nmap <C-PageDown> G:sleep 1000m<CR>:call Auto_Scroll_Down()<CR><C-PageDown>

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
:dig [] 9744
:dig [v 9745
:dig [x 9746

set noshowmode
"set statusline=%(%#ModeMsg#%{GetMode()}%*\ %)%(\ %1*%r%*\ %)%(%Y\|%)%(%M\|%)\ %{expand('%')==expand('%:t')?'':'…/'}%t%<%{GetCacheFTimeStr()}%=%k[0x%02B]\ [%{GetFF().','.AliasEnc().','.AliasEnc('f')}]%{(&scb==1?'B':'').(&wrap==1?'W':'')}\ %-5.(%l,%c%V%)\ %P
set backspace=2

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

"set clipboard+=win32yank
lua require('vscode')
