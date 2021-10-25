if exists(':GuiFont')
	"nvim-qt
	GuiFont! JetBrainsMono\ NF:h9
	GuiRenderLigatures 1
	GuiTabline 0
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
	set guifont=
				\JetBrainsMono\ NF,
				\Noto\ Sans\ CJK\ TC:h9
endif
"set guifont="JetBrains Mono NF:h11"
"set guifont=JetBrains\ Mono:h10
