if exists(':GuiFont')
	"nvim-qt
	let fontsize=9
	GuiFont! JetBrainsMono\ NF:h9
	GuiTabline 0
	sil! GuiRenderLigatures 1
	nnoremap <silent> <C-=> :let fontsize+=1 \| exec "GuiFont! JetBrainsMono\ NF:h".fontsize<CR>
	nnoremap <silent> <C--> :let fontsize-=1 \| exec "GuiFont! JetBrainsMono\ NF:h".fontsize<CR>
elseif exists('g:fvim_loaded')
	"fvim
	set guifont=JetBrains\ Mono:h10
	set guifontwide=Noto\ Sans\ CJK\ TC:h10
	FVimCursorSmoothBlink v:true
	FVimCursorSmoothMove v:true
	FVimFontLigature v:true
	nnoremap <silent> <C-ScrollWheelUp> :set guifont=+<CR>
	nnoremap <silent> <C-ScrollWheelDown> :set guifont=-<CR>
	nnoremap <silent> <C-+> :set guifont=+<CR>
	nnoremap <silent> <C-minus> :set guifont=-<CR>
	nnoremap <M-CR> :FVimToggleFullScreen<CR>
elseif exists(':GonvimVersion')
	"goneovim
	set guifont=JetBrainsMono\ NF:h9
	let fontsize=9
	nnoremap <silent> <C-=> :let fontsize+=1 \| exec "set guifont=JetBrainsMono\ NF:h".fontsize<CR>
	nnoremap <silent> <C--> :let fontsize-=1 \| exec "set guifont=JetBrainsMono\ NF:h".fontsize<CR>
else
	"neovide
	set guifont=JetBrainsMono\ NF:h9
				"\Noto\ Sans\ CJK\ TC:h9
	let g:neovide_cursor_vfx_mode = "ripple"
	let fontsize=9
	nnoremap <silent> <C-=> :let fontsize+=1 \| exec "set guifont=JetBrainsMono\ NF:h".fontsize<CR>
	nnoremap <silent> <C--> :let fontsize-=1 \| exec "set guifont=JetBrainsMono\ NF:h".fontsize<CR>
endif
"set guifont="JetBrains Mono NF:h11"
"set guifont=JetBrains\ Mono:h10
