if exists(':GuiFont')
	"nvim-qt
	GuiFont! JetBrainsMono\ NF:h9
	GuiTabline 0
	sil! GuiRenderLigatures 1
elseif exists('g:fvim_loaded')
	"fvim
	set guifont=JetBrains\ Mono:h10
	set guifontwide=Noto\ Sans\ CJK\ TC:h10
	FVimCursorSmoothBlink v:true
	FVimCursorSmoothMove v:true
	FVimFontLigature v:true
	nnoremap <silent> <C-ScrollWheelUp> :set guifont=+<CR>
	nnoremap <silent> <C-ScrollWheelDown> :set guifont=-<CR>
	nnoremap <M-CR> :FVimToggleFullScreen<CR>
elseif exists(':GonvimVersion')
	"goneovim
	set guifont=JetBrainsMono\ NF:h9
else
	"neovide
	set guifont=JetBrainsMono\ NF:h9
				"\Noto\ Sans\ CJK\ TC:h9
	let g:neovide_cursor_vfx_mode = "ripple"
endif
"set guifont="JetBrains Mono NF:h11"
"set guifont=JetBrains\ Mono:h10
