command! -nargs=? -bang UTree :call <SID>MakeUndotree("<args>", "<bang>")
command! -nargs=0 -bang UTreeAll :call <SID>MakeUndotree('0', "<bang>")

let s:Uhead = 0
let s:Utail = 0
let s:tree = []
let s:nowtime = 0

"function! <SID>MakeUndotree()
function! <SID>MakeUndotree(count, bang)
	let l:tree = undotree()
	let l:entries = l:tree.entries
	let l:limit = &lines -6
	let l:pos = [0, 0]
	let l:cur_seq = [l:tree.seq_cur, 0, l:tree.seq_cur]

	"call TravelUndotree('', l:entries)
	let s:tree = [{'seq':0, 'ucount':0}]
	let s:nowtime = localtime()
	let s:tree += s:MarkUndotree(l:entries, l:cur_seq, 0, (a:bang == '!' ? 0 : 1))
	let l:list = s:TravelUndotree(s:tree, l:cur_seq[0], '', '', '', l:pos)

	let l:count = len(l:list)
	if a:count != ''
		let l:limit = str2nr(a:count)
		if l:limit <= 0 || l:limit > l:count
			let l:limit = l:count
		endif
	endif

	if l:limit >= l:count
		let l:startp = 0
		let l:endp = l:count
	else
		if l:count - l:pos[0] > l:limit / 2
			let l:startp = (l:pos[0] > l:limit / 2 ? l:pos[0] - l:limit / 2 : 0)
			let l:endp = l:startp + l:limit
		else
			let l:endp = (l:count - l:pos[0] > l:limit / 2 ? l:pos[0] + l:limit / 2 : l:count)
			let l:startp = l:endp - l:limit
		endif
	endif

	echo strftime('%Y-%m-%d %H:%M:%S', s:nowtime)
	echo "# Undo-Tree: ".l:cur_seq[2]."-".l:tree.seq_last
	if l:startp > 0
		echo "---------- --------   Skipped ".l:startp." lines"
	endif
	while l:startp < l:endp
		if l:startp == l:pos[0]
			echohl Title
			echo l:list[l:startp]
			echohl None
		else
			echo l:list[l:startp]
		endif
		let l:startp += 1
	endwhile
	if l:endp < len(l:list)
		echo "---------- --------   Skipped ".(len(l:list)-l:endp)." lines"
	endif
	return s:tree
endfunction

function! s:MarkUndotree(entries, cur_seq, nottoplvl, skipsave)
	let l:i = 0
	let l:count = len(a:entries)
	if l:count == 0
		return []
	endif
	let l:tree = []
	let l:add = 0
	let l:skipsave = 0
	let l:undocount = 0
	let l:timestamp = 0
	while l:i < l:count
		let l:cur = a:entries[l:i]
		if l:cur.seq < a:cur_seq[2]
			let a:cur_seq[2] = l:cur.seq
		endif
		let l:undocount += 1
		if has_key(l:cur, 'alt')
			if l:i > 0 && l:add == 0
				let l:node = a:entries[l:i-1]
				"let l:tree += [{'seq':l:node.seq, 'val':'['.l:node.seq.']: '. strftime('%Y-%m-%d %X', l:node.time)}]
				let l:tree += [{'seq':l:node.seq, 'time':l:node.time, 'ucount':l:undocount-1}]
			endif
			let l:tree += [s:MarkUndotree(l:cur.alt, a:cur_seq, 1, a:skipsave)]
			if (a:nottoplvl == 0 && a:cur_seq[1] == 1)
				let a:cur_seq[0] = (l:i > 0 ? a:entries[l:i-1].seq : 0)
				let a:cur_seq[1] = 0
			endif
			let l:undocount = 1
			if has_key(l:cur, 'save')
				let l:tree += [{'seq':l:cur.seq, 'time':l:cur.time, 'save':l:cur.save, 'ucount':l:undocount}]
			else
				let l:tree += [{'seq':l:cur.seq, 'time':l:cur.time, 'ucount':l:undocount}]
			endif
			let l:timestamp = l:cur.time
			let l:add = 1
			let l:skipsave = 0
			let l:undocount = 0
			let a:cur_seq[1] = (l:cur.seq == a:cur_seq[0] ? a:nottoplvl : a:cur_seq[1])
		elseif has_key(l:cur, 'save')
			if l:skipsave == 1 && l:timestamp + 3600 >= l:cur.time
				let l:undocount = l:tree[len(l:tree)-1].ucount + l:undocount
				let l:tree[len(l:tree)-1] = {'seq':l:cur.seq, 'time':l:cur.time, 'save':l:cur.save, 'ucount':l:undocount}
			else
				let l:tree += [{'seq':l:cur.seq, 'time':l:cur.time, 'save':l:cur.save, 'ucount':l:undocount}]
				let l:timestamp = l:cur.time
			endif
			let l:add = 1
			let l:skipsave = (l:cur.seq == a:cur_seq[0] ? 0 : a:skipsave)
			let l:undocount = 0
			let a:cur_seq[1] = (l:cur.seq == a:cur_seq[0] ? a:nottoplvl : a:cur_seq[1])
		elseif l:i == 0
			let l:tree += [{'seq':l:cur.seq, 'time':l:cur.time, 'ucount':l:undocount}]
			let l:add = 1
			let l:skipsave = 0
			let l:undocount = 0
			let l:timestamp = l:cur.time
			let a:cur_seq[1] = (l:cur.seq == a:cur_seq[0] ? a:nottoplvl : a:cur_seq[1])
		elseif l:cur.seq == a:cur_seq[0]
			let l:tree += [{'seq':l:cur.seq, 'time':l:cur.time, 'ucount':l:undocount}]
			let l:add = 1
			let l:skipsave = 0
			let l:undocount = 0
			let l:timestamp = l:cur.time
			let a:cur_seq[1] = a:nottoplvl
		elseif l:timestamp + 3600 < l:cur.time 
			let l:tree += [{'seq':l:cur.seq, 'time':l:cur.time, 'ucount':l:undocount}]
			let l:add = 1
			let l:skipsave = 0
			let l:undocount = 0
			let l:timestamp = l:cur.time
			let a:cur_seq[1] = a:cur_seq[1]
		else
			let l:add = 0
		endif
		let l:i += 1
	endwhile
	if l:add == 0
		let l:tree += [{'seq':l:cur.seq, 'time':l:cur.time, 'ucount':l:undocount}]
	endif
	return l:tree
endfunction

function! s:TravelUndotree(tree, cur_seq, head, body, prefix, ppos)
	let l:i = 0
	let l:count = len(a:tree)
	let l:tree = []
	let l:time = []
	let l:add = 0
	while l:i < l:count
		if exists("l:cur")
			unlet l:cur
		endif
		let l:cur = a:tree[l:i]
		if type(l:cur) == type([])
			let l:before = a:ppos[1]
			let l:bpos = a:ppos[0]
			if a:body == ''
				let l:subtree = s:TravelUndotree(l:cur, a:cur_seq, "\u2514\u2500", "  ", " \u2502", a:ppos)
			elseif l:add == 0
				let l:subtree = s:TravelUndotree(l:cur, a:cur_seq, "\u2514\u2500", a:body, a:prefix."\u2502", a:ppos)
			else
				let l:subtree = s:TravelUndotree(l:cur, a:cur_seq, "\u2514\u2500", a:body, a:prefix."   \u2502", a:ppos)
			endif
			let l:tree += l:subtree
			if a:ppos[1] == 0
				let a:ppos[0] = l:bpos + len(l:subtree) - 1
			elseif l:before == 0
				let a:ppos[0] += l:i
			endif
		else
			let l:timestr = (has_key(l:cur, 'time') ? s:Time2Str(l:cur.time) : '| Earliest Change |')
			let l:altstr = ''
			let l:prestr = '    '
			if has_key(l:cur, 'save')
				let l:altstr .= "  (SAVE #".l:cur.save.")"
			endif
			if l:cur.seq == a:cur_seq
				let l:altstr .= '  <== Current Position'
				let a:ppos[0] += l:i
				let a:ppos[1] = 1
			endif
			if l:cur.ucount > 1
				let l:tree += [l:timestr.'    '.a:prefix.(l:add == 0 ? a:head : a:body).'['.l:cur.seq.']  '.l:cur.ucount.'-undo'.l:altstr]
			else
				let l:tree += [l:timestr.'    '.a:prefix.(l:add == 0 ? a:head : a:body).'['.l:cur.seq.']'.l:altstr]
			endif
			let l:add = 1
		endif
		let l:i += 1
	endwhile
	return l:tree
endfunction

function! s:Time2Str(time)
	let l:timediff = s:nowtime - a:time
	if l:timediff < 60
		return printf('            %2ds ago', l:timediff)
	elseif l:timediff < 3600
		return printf('        %2dm %02ds ago', l:timediff/60, l:timediff%60)
	elseif strftime('%Y%m%d',s:nowtime) == strftime('%Y%m%d',a:time)
		return strftime('  Today    %H:%M:%S', a:time)
	endif
	return strftime('%Y-%m-%d %H:%M:%S', a:time)
endfunction
