-- define some colors

local bar_fg = "#565c64"
local activeBuffer_fg = "#c8ccd4"
local selected_bg = "#0e121a"

require "bufferline".setup {
  options = {
    offsets = {{filetype = "NvimTree", text = "Explorer"}},
    buffer_close_icon = "",
    modified_icon = "",
    close_icon = " ",
    left_trunc_marker = "",
    right_trunc_marker = "",
    max_name_length = 14,
    max_prefix_length = 13,
    tab_size = 20,
    show_tab_indicators = true,
    enforce_regular_tabs = false,
    view = "multiwindow",
    show_buffer_close_icons = true,
    separator_style = "thin",
    numbers = function(opts)
      return string.format('%s', opts.id)
    end,
    custom_filter = function(buf, buf_nums)
      -- dont show help buffers in the bufferline
      if vim.bo[buf].filetype == "help" then return false end
      if vim.bo[buf].filetype == "qf" then return false end
      return true
    end
  },
  -- bar colors!!
  highlights = {
    fill = {
      guifg = bar_fg,
      guibg = "#252931"
    },
    background = {
      guifg = bar_fg,
      guibg = "#252931"
    },
    -- buffer
    buffer_selected = {
      guifg = activeBuffer_fg,
      guibg = selected_bg,
      gui = "bold"
    },
    buffer_visible = {
      guifg = "#9298a0",
      guibg = "#252931"
    },
    close_button = {
      guibg = "#252931"
    },
    close_button_visible = {
      guibg = "#252931"
    },
    close_button_selected = {
      guibg = selected_bg
    },
    -- tabs over right
    tab = {
      guifg = "#9298a0",
      guibg = "#30343c"
    },
    tab_selected = {
      guifg = "#30343c",
      guibg = "#9298a0"
    },
    tab_close = {
      guifg = "#f9929b",
      guibg = "#252931"
    },
    -- buffer separators
    separator = {
      guifg = "#252931",
      guibg = "#252931"
    },
    separator_selected = {
      guifg = selected_bg,
      guibg = selected_bg
    },
    separator_visible = {
      guifg = "#252931",
      guibg = "#252931"
    },
    indicator_selected = {
      guifg = "#252931",
      guibg = "#252931"
    },
    -- modified files (but not saved)
    modified_selected = {
      guifg = "#A3BE8C",
      guibg = selected_bg
    },
    modified_visible = {
      guifg = "#BF616A",
      guibg = "#23272f"
    }
  }
}

local opt = {silent = true}
local map = vim.api.nvim_set_keymap

-- move between tabs
map("n", "<TAB>", [[<Cmd>BufferLineCycleNext<CR>]], opt)
map("n", "<S-TAB>", [[<Cmd>BufferLineCyclePrev<CR>]], opt)
