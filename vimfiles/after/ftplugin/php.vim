
" Section jumping: [[ and ]] provided by Antony Scriven <adscriven at gmail dot com>
let s:function = '\(abstract\s\+\|final\s\+\|private\s\+\|protected\s\+\|public\s\+\|static\s\+\)*function'
let s:class = '\(private\s\+\|protected\s\+\|public\s\+\)*class'
let s:interface = 'interface'
let s:section = '\(.*\%#\)\@!\_^\s*\zs\('.s:function.'\|'.s:class.'\|'.s:interface.'\)'
exe 'nno <buffer> <silent> [[ @=":silent call search(''' . escape(s:section, '\|') . "', 'sWb')" . '\n"<CR>^'
exe 'nno <buffer> <silent> ]] @=":silent call search(''' . escape(s:section, '\|') . "', 'sW')" . '\n"<CR>^'

