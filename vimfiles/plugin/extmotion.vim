if exists('g:loaded_extmotion')
	finish
endif
let g:loaded_extmotion = 1

if !exists('g:em_boundary')
	let g:em_boundary='\s*$'
endif
if !exists('g:em_skipfold')
	let g:em_skipfold=0
endif
if !exists('g:em_scanComment')
	let g:em_scanComment=1
endif

let s:hlCom = synIDtrans(hlID('Comment'))

nnoremap <silent> [[ :<C-U>call <SID>SearchPairBack()<CR>
nnoremap <silent> ]] :<C-U>call <SID>SearchPairFore()<CR>
vnoremap <silent> [[ :<C-U>exe "normal! gv"<Bar>call <SID>SearchPairBack()<CR>
vnoremap <silent> ]] :<C-U>exe "normal! gv"<Bar>call <SID>SearchPairFore()<CR>

nnoremap <silent> { :<C-U>call <SID>ParagBack()<CR>
nnoremap <silent> } :<C-U>call <SID>ParagFore()<CR>
vnoremap <silent> { :<C-U>exe "normal! gv"<Bar>call <SID>ParagBack()<CR>
vnoremap <silent> } :<C-U>exe "normal! gv"<Bar>call <SID>ParagFore()<CR>

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
		normal zO
	endif
endfunction

function! <SID>SearchPairBack()
	normal m'
	let l:skipStr = (g:em_scanComment == 0 ? '' : 'synIDtrans(synID(line("."),col("."),1)) =~? s:hlCom')
	let l:res = searchpair('{','','}','rWb', l:skipStr)
	let l:count = v:count1
	" check if cursor did not move
	if l:res <= 0 || l:count > 1
		if l:res > 0
			let l:count = l:count - 1
		endif
		let l:res = search('}', 'Wb')
		while (l:res != 0 && g:em_scanComment && synIDtrans(synID(line("."),col("."),1)) =~? s:hlCom)
			let l:res = search('}', 'Wb')
		endwhile
		let l:res = searchpair('{','','}','rWb', l:skipStr)
		let l:count = l:count - 1
		while l:res > 0 && l:count > 0
			let l:res = search('}', 'Wb')
			while (l:res != 0 && g:em_scanComment && synIDtrans(synID(line("."),col("."),1)) =~? s:hlCom)
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
		return s:CheckFold()
	endif
	return s:CheckFold()
endfunction

function! <SID>SearchPairFore()
	normal m'
	let l:count = v:count1
	let l:skipStr = (g:em_scanComment == 0 ? '' : 'synIDtrans(synID(line("."),col("."),1)) =~? s:hlCom')
	normal $
	let l:res = searchpair('{','','}','rW', l:skipStr)
	let l:res = search('{', 'W')
	while (l:res != 0 && g:em_scanComment && synIDtrans(synID(line("."),col("."),1)) =~? s:hlCom)
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
		while (l:res != 0 && g:em_scanComment && synIDtrans(synID(line("."),col("."),1)) =~? s:hlCom)
			let l:res = search('{', 'W')
		endwhile
		" check if cursor did not move
		if l:res <= 0
			call cursor(line('$'),1)
			return s:CheckFold()
		endif
		let l:count = l:count - 1
	endwhile
	return s:CheckFold()
endfunction

function! <SID>ParagBack()
	let l:boundary='^\%('.(exists('b:em_boundary') ? b:em_boundary : g:em_boundary).'\)'
	let l:notboundary=l:boundary.'\@!'
	let l:res = search(l:notboundary, 'scWb')
	if l:res <= 0
		call cursor(1,1)
		return s:CheckFold()
	endif
	let l:res = search(l:boundary, 'Wb')
	if l:res <= 0
		call cursor(1,1)
		return s:CheckFold()
	endif
	if !g:em_skipfold || foldtextresult('.') =~# '^$'
		let l:count = v:count1 - 1
	else
		let l:count = v:count1
	endif
	while l:count > 0
		let l:res = search(l:notboundary, 'cWb')
		let l:res = search(l:boundary, 'Wb')
		if l:res <= 0
			call cursor(1,1)
			return s:CheckFold()
		endif
		if !g:em_skipfold || foldtextresult('.') =~# '^$'
			let l:count = l:count - 1
		endif
	endwhile
	return s:CheckFold()
endfunction

function! <SID>ParagFore()
	let l:boundary='^\%('.(exists('b:em_boundary') ? b:em_boundary : g:em_boundary).'\)'
	let l:notboundary=l:boundary.'\@!'
	if getline('.') =~# l:boundary
		let l:res = search(l:notboundary, 'sW')
		if l:res <= 0
			call cursor(line('$'),1)
			return s:CheckFold()
		endif
	endif
	let l:res = search(l:boundary, 'W')
	if l:res <= 0
		call cursor(line('$'),1)
		return s:CheckFold()
	endif
	if !g:em_skipfold || foldtextresult('.') =~# '^$'
		let l:count = v:count1 - 1
	else
		let l:count = v:count1
	endif
	while l:count > 0
		let l:res = search(l:notboundary, 'cW')
		let l:res = search(l:boundary, 'W')
		if l:res <= 0
			call cursor(line('$'),1)
			return s:CheckFold()
		endif
		if !g:em_skipfold || foldtextresult('.') =~# '^$'
			let l:count = l:count - 1
		endif
	endwhile
	return s:CheckFold()
endfunction

function! <SID>RepeatSearch(word, flag)
	normal m'
	let l:count=v:count1
	while l:count > 0
		call search(a:word, a:flag)
		let l:count=l:count-1
	endwhile
endfunction
