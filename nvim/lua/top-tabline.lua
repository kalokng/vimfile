local map = vim.api.nvim_set_keymap
local opts = {noremap = true, silent = true}

map('n', '<C-Tab>', ':BufferNext<CR>', opts)
map('n', '<C-S-Tab>', ':BufferPrevious<CR>', opts)
map('n', '<C-Right>', ':BufferNext<CR>', opts)
map('n', '<C-Left>', ':BufferPrevious<CR>', opts)
map('n', '<M->>', ':BufferMoveNext<CR>', opts)
map('n', '<M-<>', ':BufferMovePrevious<CR>', opts)
map('n', '<M-x>', ':BufferClose<CR>', opts)

local theme = {}
theme = {
  bg = '#202328',
  fg = '#bbc2cf',
  yellow = '#ECBE7B',
  cyan = '#008080',
  darkblue = '#081633',
  green = '#98be65',
  orange = '#FF8800',
  violet = '#a9a1e1',
  magenta = '#c678dd',
  blue = '#51afef',
  red = '#ec5f67',
  teal = '#005131',
  dark = '#0e121a',
  darkred = '#401020',
  grey = '#222c40',
}

vim.g.bufferline = {
  icon_pinned = '車',
}

vim.api.nvim_command('hi BufferCurrent guibg='..theme.teal) 
vim.api.nvim_command('hi BufferCurrentMod guifg='..theme.orange..' guibg='..theme.teal) 
vim.api.nvim_command('hi BufferCurrentSign guibg='..theme.teal) 
vim.api.nvim_command('hi BufferCurrentIcon guibg='..theme.teal) 
vim.api.nvim_command('hi BufferCurrentIndex guibg='..theme.teal) 
vim.api.nvim_command('hi BufferCurrentTarget guibg='..theme.teal) 
vim.api.nvim_command('hi BufferVisibleMod guifg='..theme.orange..' guibg='..theme.grey) 
vim.api.nvim_command('hi BufferVisible guibg='..theme.grey) 
vim.api.nvim_command('hi BufferVisibleSign guibg='..theme.grey) 
vim.api.nvim_command('hi BufferVisibleIcon guibg='..theme.grey) 
vim.api.nvim_command('hi BufferVisibleIndex guibg='..theme.grey) 
vim.api.nvim_command('hi BufferVisibleTarget guibg='..theme.grey) 

vim.api.nvim_command('hi BufferInactive guifg=#bbc2cf guibg='..theme.dark) 
vim.api.nvim_command('hi BufferInactiveMod guifg='..theme.orange..' guibg='..theme.dark) 
vim.api.nvim_command('hi BufferInactiveSign guifg=#bbc2cf guibg='..theme.dark) 
vim.api.nvim_command('hi BufferInactiveIcon guifg=#bbc2cf guibg='..theme.dark) 
vim.api.nvim_command('hi BufferInactiveIndex guifg=#bbc2cf guibg='..theme.dark) 
vim.api.nvim_command('hi BufferInactiveTarget guifg=#bbc2cf guibg='..theme.dark) 
vim.api.nvim_command('hi BufferTabpageFill guifg=#bbc2cf guibg='..theme.dark) 
vim.api.nvim_command('hi BufferTabpages guifg=#bbc2cf guibg='..theme.dark) 
--
--let fg_target = 'red'
--
--let fg_current  = s:fg(['Normal'], '#efefef')
--let fg_visible  = s:fg(['TabLineSel'], '#efefef')
--let fg_inactive = s:fg(['TabLineFill'], '#888888')
--
--let fg_modified  = s:fg(['WarningMsg'], '#E5AB0E')
--let fg_special  = s:fg(['Special'], '#599eff')
--let fg_subtle  = s:fg(['NonText', 'Comment'], '#555555')
--
--let bg_current  = s:bg(['Normal'], '#000000')
--let bg_visible  = s:bg(['TabLineSel', 'Normal'], '#000000')
--let bg_inactive = s:bg(['TabLineFill', 'StatusLine'], '#000000')
--
--" Meaning of terms:
--"
--" format: "Buffer" + status + part
--"
--" status:
--"     *Current: current buffer
--"     *Visible: visible but not current buffer
--"    *Inactive: invisible but not current buffer
--"
--" part:
--"        *Icon: filetype icon
--"       *Index: buffer index
--"         *Mod: when modified
--"        *Sign: the separator between buffers
--"      *Target: letter in buffer-picking mode
--"
--" BufferTabpages: tabpage indicator
--" BufferTabpageFill: filler after the buffer section
--" BufferOffset: offset section, created with set_offset()
--
--call s:hi_all([
--\ ['BufferCurrent',        fg_current,  bg_current],
--\ ['BufferCurrentIndex',   fg_special,  bg_current],
--\ ['BufferCurrentMod',     fg_modified, bg_current],
--\ ['BufferCurrentSign',    fg_special,  bg_current],
--\ ['BufferCurrentTarget',  fg_target,   bg_current,   'bold'],
--\ ['BufferVisible',        fg_visible,  bg_visible],
--\ ['BufferVisibleIndex',   fg_visible,  bg_visible],
--\ ['BufferVisibleMod',     fg_modified, bg_visible],
--\ ['BufferVisibleSign',    fg_visible,  bg_visible],
--\ ['BufferVisibleTarget',  fg_target,   bg_visible,   'bold'],
--\ ['BufferInactive',       fg_inactive, bg_inactive],
--\ ['BufferInactiveIndex',  fg_subtle,   bg_inactive],
--\ ['BufferInactiveMod',    fg_modified, bg_inactive],
--\ ['BufferInactiveSign',   fg_subtle,   bg_inactive],
--\ ['BufferInactiveTarget', fg_target,   bg_inactive,  'bold'],
--\ ['BufferTabpages',       fg_special,  bg_inactive, 'bold'],
--\ ['BufferTabpageFill',    fg_inactive, bg_inactive],
--\ ])
--
--call s:hi_link([
--\ ['BufferCurrentIcon',  'BufferCurrent'],
--\ ['BufferVisibleIcon',  'BufferVisible'],
--\ ['BufferInactiveIcon', 'BufferInactive'],
--\ ['BufferOffset',       'BufferTabpageFill'],
--\ ])
--
--" NOTE: this is an example taken from the source, implementation of
--" s:fg(), s:bg(), s:hi_all() and s:hi_link() is left as an exercise
--" for the reader.
