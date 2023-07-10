local gl = require('galaxyline')
local colors = require('galaxyline.theme').default
local condition = require('galaxyline.condition')
local fileinfo = require('galaxyline.provider_fileinfo')
local gls = gl.section
gl.short_line_list = {'NvimTree','vista','dbui','packer'}
--hi StatusLine guifg=#bbc2cf guifg=#202328
colors.fg = vim.fn.synIDattr(vim.fn.hlID("StatusLine"), "bg#", "gui")
colors.bg = vim.fn.synIDattr(vim.fn.hlID("StatusLine"), "fg#", "gui")
local color_darkred = '#804040'
local color_darkgreen = '#98be55'
local color_lightgray = '#c0c0c0'
local color_gray = '#808080'
local api = vim.api
--colors.bg = '#dfdebd'

local mode_color = {
  n = colors.red, i = colors.green,v=colors.blue,
  [''] = colors.blue,V=colors.blue,
  c = colors.magenta,no = colors.red,s = colors.orange,
  S=colors.orange,[''] = colors.orange,
  ic = colors.yellow,R = colors.violet,Rv = colors.violet,
  cv = colors.red,ce=colors.red, r = colors.cyan,
  rm = colors.cyan, ['r?'] = colors.cyan,
  ['!']  = colors.red,t = colors.red
}
local mode_name = {
  [''] = '^V', [''] = '^S'
}

--terminal highlight setting
local cterms={
	red=168,green=10,blue=68,
	magenta=177,orange=173,
	yellow=222,violet=89,cyan=14,
	darkred=88,darkgreen=114,
	darkblue=23,grey=8,fg=15,bg=17,
}
colors.ctermfg = vim.fn.synIDattr(vim.fn.hlID("StatusLine"), "fg#", "cterm")
colors.ctermbg = vim.fn.synIDattr(vim.fn.hlID("StatusLine"), "bg#", "cterm")
local cterm_color = {
  n = cterms.red, i = cterms.green,v=cterms.blue,
  [''] = cterms.blue,V=cterms.blue,
  c = cterms.magenta,no = cterms.red,s = cterms.orange,
  S=cterms.orange,[''] = cterms.orange,
  ic = cterms.yellow,R = cterms.violet,Rv = cterms.violet,
  cv = cterms.red,ce=cterms.red, r = cterms.cyan,
  rm = cterms.cyan, ['r?'] = cterms.cyan,
  ['!']  = cterms.red,t = cterms.red
}
api.nvim_command('hi StatusLine cterm=NONE ctermfg='..cterms.fg..' ctermbg='..cterms.bg)
api.nvim_command('hi StatusLineNC cterm=NONE ctermfg='..cterms.fg..' ctermbg='..cterms.bg)
api.nvim_command('hi StatusLineTermNC cterm=NONE ctermfg='..cterms.fg..' ctermbg='..cterms.bg)
api.nvim_command('hi GalaxyViMode cterm=bold ctermfg=16')
api.nvim_command('hi GalaxyFileSize ctermfg='..cterms.fg..' ctermbg='..cterms.bg)
api.nvim_command('hi LineInfoSeparator ctermfg='..cterms.darkblue..' ctermbg='..cterms.bg)
api.nvim_command('hi FileNameSeparator ctermfg='..cterms.darkblue..' ctermbg='..cterms.bg)
api.nvim_command('hi PerCentSeparator ctermfg='..cterms.darkblue)
api.nvim_command('hi GalaxyFileName cterm=bold ctermbg='..cterms.bg..' ctermfg='..cterms.magenta)
api.nvim_command('hi GalaxyFileIcon cterm=bold ctermbg='..cterms.bg..' ctermfg='..cterms.fg)
api.nvim_command('hi GalaxyLineInfo ctermbg='..cterms.darkblue..' ctermfg='..cterms.fg)
api.nvim_command('hi GalaxyPerCent cterm=bold ctermbg='..cterms.darkblue..' ctermfg='..cterms.fg)
api.nvim_command('hi CursorByteSeparator ctermfg='..cterms.darkred..' ctermbg='..cterms.bg)
api.nvim_command('hi GalaxyShowFTime ctermfg='..cterms.darkgreen..' ctermbg='..cterms.bg)
api.nvim_command('hi GalaxyCursorByte ctermbg='..cterms.darkred..' ctermfg='..cterms.fg)
api.nvim_command('hi FileEncodeSeparator ctermfg='..cterms.darkred..' ctermbg='..cterms.darkgreen)
api.nvim_command('hi GalaxyFileEncode ctermbg='..cterms.darkgreen..' ctermfg='..cterms.darkblue)
api.nvim_command('hi GalaxyFileFormat ctermbg='..cterms.darkgreen..' ctermfg='..cterms.darkblue)
api.nvim_command('hi FileFormatSeparator ctermbg='..cterms.darkgreen..' ctermfg='..cterms.darkblue)
api.nvim_command('hi GalaxyBufferType ctermbg='..cterms.bg..' ctermfg='..cterms.blue)
api.nvim_command('hi BufferTypeSeparator ctermbg='..cterms.bg..' ctermfg='..cterms.blue)
api.nvim_command('hi GalaxySFileDir ctermbg='..cterms.bg..' ctermfg='..cterms.grey)
api.nvim_command('hi GalaxySFileName ctermbg='..cterms.bg..' ctermfg='..cterms.fg)
api.nvim_command('hi SFileNameSeparator ctermbg='..cterms.bg..' ctermfg='..cterms.darkblue)

-- show line:column
function line_column()
  local line = vim.fn.line('.')
  local column = vim.fn.col('.')
  local vcolumn = vim.fn.virtcol('.')
  if column == vcolumn then
	  return string.format("%d,%d", line, column)
  else
	  return string.format("%d,%d-%d", line, column, vcolumn)
  end
end

-- show current line percent of all lines
function current_line_percent()
  local visual_first = vim.fn.line('w0')
  local visual_last = vim.fn.line('w$')
  local total_line = vim.fn.line('$')
  if visual_first == 1 then
	if visual_last == total_line then
	  return 'All '
	end
    return 'Top '
  elseif visual_last == total_line then
    return 'Bot '
  end
  local result,_ = math.modf((vim.fn.line('.')/total_line)*100)
  return result .. '% '
end

function special_filetype()
	local ft = vim.bo.filetype
	if ft == 'nerdtree' then return false end
	if ft == 'qf' then return false end
	return true
end

function buf_binded(mode)
	local scb = vim.wo.scb
	if scb then
		api.nvim_command('hi '..mode..' guifg='..colors.orange)
	else
		api.nvim_command('hi '..mode..' guifg='..colors.fg)
	end
end

function cache_func(key, f)
	local table = vim.b.cache_val
	if type(table) ~= "table" then
		table = { }
	end
	local v = table[key]
	if type(v) ~= "string" then
		v = f()
		table[key] = v
		vim.b.cache_val = table
	end
	return v
end

function cache_expand(key)
	return cache_func('exp('..key, function()
		return vim.fn.expand(key)
	end)
end

function file_size(file)
  local size = vim.fn.getfsize(file)
  if size == 0 or size == -1 or size == -2 then
    return ''
  end
  if size < 1024 then
    size = size .. 'b'
  elseif size < 1024 * 1024 then
    size = string.format('%.1f',size/1024) .. 'k'
  elseif size < 1024 * 1024 * 1024 then
    size = string.format('%.1f',size/1024/1024) .. 'm'
  else
    size = string.format('%.1f',size/1024/1024/1024) .. 'g'
  end
  return size .. ' '
end

function cache_filesize()
	return cache_func('filesize', function()
		local file = cache_expand('%:p')
		if string.len(file) == 0 then return '' end
		return file_size(file)
	end)
end

api.nvim_command('augroup statusline')
api.nvim_command('au! BufRead,BufWritePost,BufFilePost * unlet! b:cache_val')
api.nvim_command('augroup END')

function buf_cur_dir(mode)
	local pwd = vim.fn.getcwd()
	local dir = cache_expand('%:p:h')
	if pwd ~= dir then
		api.nvim_command('hi '..mode..' guifg='..colors.orange)
	else
		api.nvim_command('hi '..mode..' guifg='..colors.magenta)
	end
end

function cursor_char()
	if vim.fn.mode() == 'i' then return '' end
	local l = vim.fn.getline('.')
	local c = vim.fn.strcharpart(l, vim.fn.charidx(l,vim.fn.col('.')-1,1))
	if c == "" then return '×' end
	return string.format('0x%02X', vim.fn.char2nr(c))
end

gls.left[1] = {
  ViMode = {
    provider = function()
      -- auto change color according the vim mode
      local mode = vim.fn.mode()
      api.nvim_command('hi GalaxyViMode guibg='..mode_color[mode])
      api.nvim_command('hi GalaxyViMode ctermbg='..cterm_color[mode])
	  buf_binded('GalaxyLineInfo')
	  buf_binded('GalaxyPerCent')
	  buf_cur_dir('GalaxyFileName')
      local name = mode_name[mode]
      if name ~= nil then
        mode = name
      end
      return string.format('% 3s ', mode)
    end,
    highlight = {colors.bg,colors.bg,'bold'},
  }
}

gls.left[2] = {
  FileSize = {
	provider = cache_filesize,
	condition = condition.buffer_not_empty,
	highlight = {colors.fg,colors.bg}
  }
}

gls.left[3] = {
  FileIcon = {
    provider = 'FileIcon',
    condition = condition.buffer_not_empty,
    highlight = {require('galaxyline.provider_fileinfo').get_file_icon_color,colors.bg},
  }
}

gls.left[4] = {
  FileDir = {
    provider =  function()
		local path = cache_expand('%:p')
		local name = cache_expand('%:p:t')
		if vim.fn.winwidth(0) < vim.fn.strdisplaywidth(path)+10 then
			return ''
		end
		return string.sub(path,0,vim.fn.strridx(path, name))
	end,
    condition = condition.buffer_not_empty,
    highlight = {color_lightgray,colors.bg,'bold'}
  }
}

gls.left[5] = {
  FileName = {
    provider = 'FileName',
    condition = condition.buffer_not_empty,
    separator = '',
    separator_highlight = {colors.darkblue,colors.bg},
    highlight = {colors.magenta,colors.bg,'bold'}
  }
}

gls.left[6] = {
  PerCent = {
    provider = current_line_percent,
    highlight = {colors.fg,colors.darkblue,'bold'},
  }
}

gls.left[7] = {
  LineInfo = {
    provider = line_column,
    separator = '',
    separator_highlight = {colors.darkblue,colors.bg},
    highlight = {colors.fg,colors.darkblue},
	--highlight = "guifg="..colors.fg.." guibg="..colors.darkblue.." ctermfg="..colors.ctermbg.." ctermbg="..colors.ctermfg,
  },
}

gls.left[8] = {
  DiagnosticError = {
    provider = 'DiagnosticError',
    icon = '  ',
    highlight = {colors.red,colors.bg}
  }
}

gls.left[9] = {
  DiagnosticWarn = {
    provider = 'DiagnosticWarn',
    icon = '  ',
    highlight = {colors.yellow,colors.bg},
  }
}

gls.left[10] = {
  DiagnosticHint = {
    provider = 'DiagnosticHint',
    icon = '  ',
    highlight = {colors.cyan,colors.bg},
  }
}

gls.left[11] = {
  DiagnosticInfo = {
    provider = 'DiagnosticInfo',
    icon = '  ',
    highlight = {colors.blue,colors.bg},
  }
}

gls.mid[1] = {
  ShowLspClient = {
    provider = function()
		if vim.fn.exists('g:coc_enabled') == 0 then return '' end
		return vim.fn['coc#status']()
	end,
    condition = condition.hide_in_width,
    icon = ':',
    highlight = {colors.cyan,colors.bg,'bold'}
  }
}

gls.right[1] = {
  ShowFTime = {
	provider = vim.fn.GetCacheFTimeStr,
	condition = function()
      if not special_filetype() then return false end
	  if vim.fn.winwidth(0) >= 70 then
		return true
	  end
	  return false
	end,
	icon = '',
	highlight = {colors.green,colors.bg}
  }
}

gls.right[2] = {
  CursorByte = {
	provider = cursor_char,
    condition = special_filetype,
	separator = '',
	separator_highlight = {color_darkred,colors.bg},
	highlight = {colors.fg,color_darkred}
  }
}

gls.right[3] = {
  FileEncode = {
    provider = vim.fn.AliasEnc,
    condition = special_filetype,
    separator = '',
    separator_highlight = {color_darkred,color_darkgreen},
    highlight = {colors.bg,color_darkgreen,'bold'}
  }
}

gls.right[4] = {
  FileFormat = {
    provider = 'FileFormat',
    condition = special_filetype,
    separator = ' ',
    separator_highlight = {'NONE',color_darkgreen},
    highlight = {colors.bg,color_darkgreen,'bold'}
  }
}

gls.short_line_left[1] = {
  BufferType = {
    provider = 'FileTypeName',
    separator = ' ',
    separator_highlight = {'NONE',colors.bg},
    highlight = {colors.blue,colors.bg,'bold'}
  }
}

gls.short_line_left[2] = {
  FileSize = {
	provider = cache_filesize,
	condition = condition.buffer_not_empty,
	highlight = {colors.fg,colors.bg}
  }
}

gls.short_line_left[3] = {
  SFileDir = {
    provider =  function()
		local path = cache_expand('%:p')
		local name = cache_expand('%:p:t')
		if vim.fn.winwidth(0) < vim.fn.strdisplaywidth(path)+10 then
			return ''
		end
		return string.sub(path,0,vim.fn.strridx(path, name))
	end,
    condition = condition.buffer_not_empty,
    highlight = {color_gray,colors.bg}
  }
}

gls.short_line_left[4] = {
  SFileName = {
    provider = 'SFileName',
    condition = condition.buffer_not_empty,
	separator = '',
    separator_highlight = {colors.darkblue,colors.bg},
    highlight = {colors.fg,colors.bg,'bold'}
  }
}

gls.short_line_left[5] = {
  PerCent = {
    provider = current_line_percent,
    highlight = {colors.fg,colors.darkblue,'bold'},
  }
}

gls.short_line_left[6] = {
  LineInfo = {
    provider = line_column,
    separator = '',
    separator_highlight = {colors.darkblue,colors.bg},
    highlight = {colors.fg,colors.darkblue},
	--highlight = "guifg="..colors.fg.." guibg="..colors.darkblue.." ctermfg="..colors.ctermbg.." ctermbg="..colors.ctermfg,
  },
}

gls.short_line_right[1] = {
  BufferIcon = {
    provider= 'BufferIcon',
    highlight = {colors.fg,colors.bg}
  }
}

gls.short_line_right[2] = {
  Binded = {
    provider= function()
	  local scb = vim.wo.scb
	  if scb then return 'B' end
	  return ''
	end,
    highlight = {colors.fg,colors.bg}
  }
}
