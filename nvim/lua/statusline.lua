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
local color_gray = '#808080'
--colors.bg = '#dfdebd'

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

function special_filetype()
	local ft = vim.bo.filetype
	if ft == 'nerdtree' then return false end
	if ft == 'qf' then return false end
	return true
end

function buf_binded(mode)
	local scb = vim.wo.scb
	if scb then
		vim.api.nvim_command('hi '..mode..' guifg='..colors.orange)
	else
		vim.api.nvim_command('hi '..mode..' guifg='..colors.fg)
	end
end

gls.left = {}

table.insert(gls.left, {
  ViMode = {
    provider = function()
      -- auto change color according the vim mode
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
      local mode = vim.fn.mode()
      vim.api.nvim_command('hi GalaxyViMode guibg='..mode_color[mode])
	  buf_binded('GalaxyLineInfo')
	  buf_binded('GalaxyPerCent')
      local name = mode_name[mode]
      if name ~= nil then
        mode = name
      end
      return string.format('% 3s ', mode)
    end,
    highlight = {colors.bg,colors.bg,'bold'},
  }
})

table.insert(gls.left, {
  FileSize = {
	provider = 'FileSize',
	condition = condition.buffer_not_empty,
	highlight = {colors.fg,colors.bg}
  }
})

table.insert(gls.left, {
  FileIcon = {
    provider = 'FileIcon',
    condition = condition.buffer_not_empty,
    highlight = {require('galaxyline.provider_fileinfo').get_file_icon_color,colors.bg},
  }
})

table.insert(gls.left, {
  FileName = {
    provider = 'FileName',
    condition = condition.buffer_not_empty,
    separator = '',
    separator_highlight = {colors.darkblue,colors.bg},
    highlight = {colors.magenta,colors.bg,'bold'}
  }
})

table.insert(gls.left, {
  PerCent = {
    provider = 'LinePercent',
    highlight = {colors.fg,colors.darkblue,'bold'},
  }
})

table.insert(gls.left, {
  LineInfo = {
    provider = line_column,
    separator = '',
    separator_highlight = {colors.darkblue,colors.bg},
    highlight = {colors.fg,colors.darkblue},
  },
})

table.insert(gls.left, {
  DiagnosticError = {
    provider = 'DiagnosticError',
    icon = '  ',
    highlight = {colors.red,colors.bg}
  }
})

table.insert(gls.left, {
  DiagnosticWarn = {
    provider = 'DiagnosticWarn',
    icon = '  ',
    highlight = {colors.yellow,colors.bg},
  }
})

table.insert(gls.left, {
  DiagnosticHint = {
    provider = 'DiagnosticHint',
    icon = '  ',
    highlight = {colors.cyan,colors.bg},
  }
})

table.insert(gls.left, {
  DiagnosticInfo = {
    provider = 'DiagnosticInfo',
    icon = '  ',
    highlight = {colors.blue,colors.bg},
  }
})

gls.mid = {}

table.insert(gls.mid, {
  ShowLspClient = {
    provider = function()
		if vim.fn.exists('g:coc_enabled') == 0 then return '' end
		return vim.fn['coc#status']()
	end,
    condition = condition.hide_in_width,
    icon = ':',
    highlight = {colors.cyan,colors.bg,'bold'}
  }
})

gls.right = {}

table.insert(gls.right, {
  ShowFTime = {
	provider = function()
	  return vim.fn.GetCacheFTime()
	end,
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
})

table.insert(gls.right, {
  CursorByte = {
	provider = function()
	  if vim.fn.mode() == 'i' then return '' end
	  local l = vim.fn.getline('.')
	  local c = vim.fn.strcharpart(l, vim.fn.charidx(l,vim.fn.col('.')-1,1))
	  if c == "" then return '×' end
	  return string.format('0x%02X', vim.fn.char2nr(c))
	end,
    condition = special_filetype,
	separator = '',
	separator_highlight = {color_darkred,colors.bg},
	highlight = {colors.fg,color_darkred}
  }
})

table.insert(gls.right, {
  FileEncode = {
    provider = function()
		local fenc = vim.fn.AliasEnc('f')
		local enc = vim.fn.AliasEnc()
		if fenc == enc or fenc == '--' then return enc end
		return enc .. ' ' .. fenc
	end,
    condition = special_filetype,
    separator = '',
    separator_highlight = {color_darkred,color_darkgreen},
    highlight = {colors.bg,color_darkgreen,'bold'}
  }
})

table.insert(gls.right, {
  FileFormat = {
    provider = 'FileFormat',
    condition = special_filetype,
    separator = ' ',
    separator_highlight = {'NONE',color_darkgreen},
    highlight = {colors.bg,color_darkgreen,'bold'}
  }
})

table.insert(gls.right, {
  GitIcon = {
    provider = function() return ' ' end,
    condition = condition.check_git_workspace,
	separator = '',
    separator_highlight = {colors.violet,color_darkgreen},
    highlight = {colors.bg,colors.violet,'bold'},
  }
})

table.insert(gls.right, {
  GitBranch = {
    provider = 'GitBranch',
    condition = condition.check_git_workspace,
    highlight = {colors.bg,colors.violet,'bold'},
  }
})

table.insert(gls.right, {
  DiffAdd = {
    provider = 'DiffAdd',
    icon = '',
    highlight = {colors.green,colors.bg},
  }
})

table.insert(gls.right, {
  DiffModified = {
    provider = 'DiffModified',
    icon = '柳',
    highlight = {colors.orange,colors.bg},
  }
})

table.insert(gls.right, {
  DiffRemove = {
    provider = 'DiffRemove',
    icon = '',
    highlight = {colors.red,colors.bg},
  }
})

gls.short_line_left[1] = {
  BufferType = {
    provider = 'FileTypeName',
    separator = ' ',
    separator_highlight = {'NONE',colors.bg},
    highlight = {colors.blue,colors.bg,'bold'}
  }
}

gls.short_line_left[2] = {
  SFileDir = {
    provider =  function()
		local path = vim.fn.expand('%:p')
		local name = vim.fn.expand('%:p:t')
		if vim.fn.winwidth(0) < vim.fn.strdisplaywidth(path)+10 then
			return ''
		end
		return string.sub(path,0,vim.fn.strridx(path, name))
	end,
    condition = condition.buffer_not_empty,
    highlight = {color_gray,colors.bg}
  }
}

gls.short_line_left[3] = {
  SFileName = {
    provider = 'SFileName',
    condition = condition.buffer_not_empty,
    highlight = {colors.fg,colors.bg,'bold'}
  }
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
