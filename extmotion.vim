if exists('g:loaded_extmotion')
	finish
endif
let g:loaded_extmotion = 1

let s:hlCom = synIDtrans(hlID('Comment'))

nnoremap <silent> [[ :<C-U>call <SID>SearchPairBack()<CR>
nnoremap <silent> ]] :<C-U>call <SID>SearchPairFore()<CR>
vnoremap <silent> [[ :<C-U>exe "normal! gv"<Bar>call <SID>SearchPairBack()<CR>
vnoremap <silent> ]] :<C-U>exe "normal! gv"<Bar>call <SID>SearchPairFore()<CR>

nnoremap <silent> [) :<C-U>call <SID>RepeatSearch(')','Wb')<CR>
nnoremap <silent> ]( :<C-U>call <SID>RepeatSearch('(','W')<CR>
vnoremap <silent> [) :<C-U>exe "normal! gv"<Bar>call <SID>RepeatSearch(')','Wb')<CR>
vnoremap <silent> ]( :<C-U>exe "normal! gv"<Bar>call <SID>RepeatSearch('(','W')<CR>

nnoremap <silent> [} :<C-U>call <SID>RepeatSearch('}','Wb')<CR>
nnoremap <silent> ]{ :<C-U>call <SID>RepeatSearch('{','W')<CR>
vnoremap <silent> [} :<C-U>exe "normal! gv"<Bar>call <SID>RepeatSearch('}','Wb')<CR>
vnoremap <silent> ]{ :<C-U>exe "normal! gv"<Bar>call <SID>RepeatSearch('{','W')<CR>

function! s:CheckFold()
	if &foldopen =~ 'block' && foldtextresult('.') !~# '^$'
		normal! zO
	endif
endfunction

function! <SID>SearchPairBack()
	let l:count = v:count1
	normal! m'
	let old = getpos('.')
	if old[1] == 1
		call cursor(0,1)
		return s:CheckFold()
	endif
	let new = old

	while l:count > 0
		let tmp = [0,0,0,0,0]
		while new != tmp
			keepjumps sil! normal! 10[{
			let tmp = new
			let new = getpos('.')
		endwhile
		if new != old
			let l:count = l:count-1
		endif
		if l:count > 0
			let l:res = search('}', 'Wb')
			if res == 0
				call cursor(1,1)
				return s:CheckFold()
			endif
		endif
	endwhile
	call cursor(0,1)
	return s:CheckFold()
endfunction

function! <SID>SearchPairFore()
	let l:count = v:count1
	normal! m'
	let old = getpos('.')
	let l:eol = line('$')
	if old[1] == eol
		call cursor(0,1)
		return s:CheckFold()
	endif
	let new = old
	echo new

	normal! $
	while l:count > 0
		let tmp = [0,0,0,0,0]
		while new != tmp
			keepjumps sil! normal! 10]}
			let tmp = new
			let new = getpos('.')
		endwhile
		let l:res = search('{', 'W')
		if res == 0
			call cursor(eol,1)
			return s:CheckFold()
		endif
		let l:count = l:count-1
	endwhile
	call cursor(0,1)
	return s:CheckFold()
endfunction

function! <SID>RepeatSearch(word, flag)
	let l:count=v:count1
	normal! m'
	while l:count > 0
		call search(a:word, a:flag)
		let l:count=l:count-1
	endwhile
endfunction

function! <SID>_SearchPairBack()
	let l:count = v:count1
	normal! m'
	let l:skipStr = (g:em_scanComment == 0 ? '' : 'synIDtrans(synID(line("."),col("."),1)) =~? s:hlCom')
	let l:res = searchpair('{','','}','rWb', l:skipStr)
	echo l:count
	" check if cursor did not move
	if l:res <= 0 || l:count > 1
		if l:res > 0
			let l:count = l:count - 1
		endif
		let l:res = search('}', 'Wb')
		while (l:res != 0 && g:em_scanComment)
			if synIDtrans(synID(line("."),col("."),1)) !~? s:hlCom
				break
			endif
			let l:res = search('}', 'Wb')
		endwhile
		let l:res = searchpair('{','','}','rWb', l:skipStr)
		let l:count = l:count - 1
		while l:res > 0 && l:count > 0
			let l:res = search('}', 'Wb')
			while (l:res != 0 && g:em_scanComment)
				if synIDtrans(synID(line("."),col("."),1)) !~? s:hlCom
					break
				endif
				let l:res = search('}', 'Wb')
			endwhile
			let l:res = searchpair('{','','}','rWb', l:skipStr)
			let l:count = l:count - 1
			if l:res <= 0
				break
			endif
		endwhile
		if l:res <= 0
			call cursor(1,1)
			return s:CheckFold()
		endif
		call cursor(0,1)
		return s:CheckFold()
	endif
	call cursor(0,1)
	return s:CheckFold()
endfunction

function! <SID>_SearchPairFore()
	let l:count = v:count1
	normal! m'
	let l:skipStr = (g:em_scanComment == 0 ? '' : 'synIDtrans(synID(line("."),col("."),1)) =~? s:hlCom')
	normal! $
	let l:res = searchpair('{','','}','rW', l:skipStr)
	let l:res = search('{', 'W')
	while (l:res != 0 && g:em_scanComment)
		if synIDtrans(synID(line("."),col("."),1)) !~? s:hlCom
			break
		endif
		let l:res = search('{', 'W')
	endwhile
	" check if cursor did not move
	if l:res <= 0
		call cursor(line('$'),1)
		return s:CheckFold()
	endif
	let l:count = l:count - 1
	while l:count > 0
		let l:res = searchpair('{','','}','rW', l:skipStr)
		let l:res = search('{', 'W')
		while (l:res != 0 && g:em_scanComment)
			if synIDtrans(synID(line("."),col("."),1)) !~? s:hlCom
				break
			endif
			let l:res = search('{', 'W')
		endwhile
		" check if cursor did not move
		if l:res <= 0
			call cursor(line('$'),1)
			return s:CheckFold()
		endif
		let l:count = l:count - 1
	endwhile
	call cursor(0,1)
	return s:CheckFold()
endfunction

