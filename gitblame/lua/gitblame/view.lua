-- Window layout, rendering and key handling for the git blame browser.
--
-- Layout in the current tabpage:
--   +----------------------------------------------+
--   | top pane: commit graph        (~1/3 height)  |
--   +--------+-------------------------------------+
--   |  meta  | content of the file at focus commit |
--   +--------+-------------------------------------+
-- The focus commit is the single source of truth: changing it re-renders all panes.
local config = require('gitblame.config')
local git = require('gitblame.git')
local graph = require('gitblame.graph')

local M = {}

local ns = vim.api.nvim_create_namespace('gitblame')
local graph_ns = vim.api.nvim_create_namespace('gitblame.graph_selection')
local views = {} -- tabpage id -> view state
local saved_scrollopt
local close_help -- forward declared; defined with the shortcut popup below
local seq = 0

-- Window-local options saved from the user's window so `q` can restore them.
local WINOPTS = {
  'scrollbind', 'scrolloff', 'wrap', 'number', 'relativenumber', 'signcolumn',
  'cursorline', 'foldenable', 'foldcolumn', 'winfixwidth', 'winfixheight', 'spell', 'list',
}

local function fail(msg)
  vim.notify('gitblame: ' .. msg, vim.log.levels.ERROR)
  return nil, msg
end

local function say(state, msg)
  if state then
    state.message = msg
  end
  vim.notify('gitblame: ' .. msg, vim.log.levels.INFO)
  return true
end

local function short(sha)
  return sha and sha:sub(1, config.get().hash_length) or ''
end

---@return table? state
local function state_for(tabpage)
  return views[tabpage or vim.api.nvim_get_current_tabpage()]
end
M.state = state_for

local function current()
  local state = state_for()
  if not state then
    return nil, 'no gitblame view in this tabpage'
  end
  return state
end

--- Replace every line of a scratch buffer and clear our highlights on it.
local function set_lines(buf, lines)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
end

local function scratch_buf(name)
  local buf = vim.api.nvim_create_buf(false, true)
  pcall(vim.api.nvim_buf_set_name, buf, name)
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].undolevels = -1
  vim.bo[buf].modifiable = false
  return buf
end

local function wset(win, opts)
  for name, value in pairs(opts) do
    pcall(vim.api.nvim_set_option_value, name, value, { win = win })
  end
end

local bind, bind_all -- defined with the keymaps below

local function path_at(state, sha)
  return state.paths[sha] or state.rel
end

-- ---------------------------------------------------------------- rendering

--- Pad or clip `author` to `width` display cells: a long name must not push the columns.
local function author_column(author, width)
  local cells = vim.fn.strdisplaywidth(author)
  while cells > width do
    author = vim.fn.strcharpart(author, 0, vim.fn.strchars(author, true) - 1, true)
    cells = vim.fn.strdisplaywidth(author)
  end
  return author .. string.rep(' ', width - cells)
end

--- Height of the graph pane: all of the history when it fits, otherwise the configured
--- share of the screen, and never less than three rows.
local function graph_height(state)
  local allowed = math.floor((vim.o.lines - 2) * config.get().top_ratio)
  return math.max(3, math.min(allowed, #state.rows))
end

local GRAPH_START = 2

local function highlight_connection(state, line, force)
  local row = state.rows[line]
  local sha = row and (row.sha or row.child)
  if not force and sha == state.graph_selection then return end
  state.graph_selection = sha
  local buf = state.bufs.graph
  vim.api.nvim_buf_clear_namespace(buf, graph_ns, 0, -1)
  local first = sha and state.index[sha]
  if not first then return end

  local targets, last = {}, first
  for _, parent in ipairs(state.rows[first].parents) do
    local parent_line = state.index[parent]
    if parent_line and parent_line > first then
      targets[parent] = parent_line
      last = math.max(last, parent_line)
    end
  end
  for i = first, last do
    local graph_row = state.rows[i]
    for _, segment in ipairs(graph_row.segments) do
      local target = targets[segment.target]
      if (i == first and segment.node) or (i > first and target and i <= target)
        or (graph_row.child == sha and segment.branch) then
        vim.api.nvim_buf_set_extmark(buf, graph_ns, i - 1, GRAPH_START + segment.start_col, {
          end_col = GRAPH_START + segment.end_col, hl_group = 'GitBlameGraphSelected', priority = 120,
        })
      end
    end
  end
end

local function render_graph(state)
  local opts = config.get()
  local buf, win = state.bufs.graph, state.wins.graph
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local added_width, removed_width = unpack(state.count_widths)
  local counts_format = ('%%%ds %%%ds'):format(added_width, removed_width)
  -- memoised author fields: one call per distinct name, reused by the highlight pass
  local authors = {}
  local function author_field(name)
    if name == '' then
      return ''
    end
    local field = authors[name]
    if not field then
      field = author_column(name, opts.author_width)
      authors[name] = field
    end
    return field
  end
  local lines, focus_row = {}, nil
  for i, row in ipairs(state.rows) do
    local art = row.art .. string.rep(' ', state.art_width - row.cells)
    if row.kind == 'commit' then
      local focused = row.sha == state.focus
      if focused then
        focus_row = i
      end
      local count = state.counts[row.sha]
      local counts = counts_format:format('+' .. (count and count.added or '?'), '-' .. (count and count.removed or '?'))
      local binary = count and count.binary and ' binary' or ''
      lines[i] = (focused and opts.focus_sign or ' ') .. ' ' .. art .. ' '
        .. short(row.sha) .. ' ' .. row.date .. ' | ' .. counts .. binary
        .. ' | ' .. author_field(row.author) .. ' | ' .. row.subject
    else
      lines[i] = '  ' .. art
    end
  end
  set_lines(buf, lines)

  for i, row in ipairs(state.rows) do
    -- Graph padding uses screen cells; extmark columns use bytes.
    local art_end = GRAPH_START + #row.art + state.art_width - row.cells
    local hash_start = art_end + 1
    vim.api.nvim_buf_set_extmark(buf, ns, i - 1, GRAPH_START, {
      end_col = art_end,
      hl_group = 'GitBlameGraph',
    })
    if row.kind == 'commit' then
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, hash_start, {
        end_col = hash_start + #short(row.sha),
        hl_group = 'GitBlameHash',
      })
      local date_start = hash_start + #short(row.sha) + 1
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, date_start, {
        end_col = date_start + #row.date, hl_group = 'GitBlameDate',
      })
      local added_start = date_start + #row.date + 3
      local removed_start = added_start + added_width + 1
      local removed_end = removed_start + removed_width
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, added_start, {
        end_col = added_start + added_width, hl_group = 'GitBlameAdded',
      })
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, removed_start, {
        end_col = removed_end, hl_group = 'GitBlameRemoved',
      })
      local author = author_field(row.author)
      if author ~= '' then
        local count = state.counts[row.sha]
        local author_start = removed_end + (count and count.binary and #' binary' or 0) + 3
        vim.api.nvim_buf_set_extmark(buf, ns, i - 1, author_start, {
          end_col = author_start + #author, hl_group = 'GitBlameAuthor',
        })
      end
      if row.sha == state.focus then
        vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, { line_hl_group = 'GitBlameFocus' })
        vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, { end_col = 1, hl_group = 'GitBlameIndicator' })
      end
    end
  end

  -- the pane follows the history length, so F and refresh re-fit it as the list changes
  if vim.api.nvim_win_is_valid(win) then
    local wanted = graph_height(state)
    if vim.api.nvim_win_get_height(win) ~= wanted then
      pcall(vim.api.nvim_win_set_height, win, wanted)
    end
  end

  if focus_row and vim.api.nvim_win_is_valid(win) then
    pcall(vim.api.nvim_win_set_cursor, win, { focus_row, 0 })
  end
  highlight_connection(state, focus_row or 1, true)
end

-- The left pane is a fixed grid: 2 change + 1 + 8 hash + 1 + author + 1 + 10 date.
-- The hash always shows 8 digits and the author takes whatever width is left, so a long
-- name or a larger hash_length can never push the date out of the pane.
local META_HASH_DIGITS = 8
local META_DATE_CELLS = 10

local function meta_author_cells(opts)
  local fixed = 2 + 1 + META_HASH_DIGITS + 1 + 1 + META_DATE_CELLS
  return math.max(1, opts.meta_width - fixed)
end

local function render_meta(state, line_count)
  local opts = config.get()
  local author_cells = meta_author_cells(opts) -- the author column absorbs the pane width
  local buf = state.bufs.meta
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local lines = {}
  local author_ends, authors = {}, {}
  for i = 1, line_count do
    local entry = state.blame[i]
    local mark = ' ' -- the change column; highlighted in the pass below
    if state.show_changes then
      if state.changes.added[i] then
        mark = '+'
      elseif state.touched[i] then
        mark = '~'
      elseif state.changes.removed[i] then
        local count = state.changes.removed[i]
        mark = count < 10 and ('-' .. count) or '-'
      end
    end
    local sha = entry and entry.sha or ''
    local hash = sha ~= '' and sha:sub(1, META_HASH_DIGITS) or string.rep('-', META_HASH_DIGITS)
    if sha ~= '' and sha:match('^0+$') then
      hash = 'WORKTREE'
    end
    local prefix = string.format('%-2s %-' .. META_HASH_DIGITS .. 's ', mark, hash)
    local name = entry and entry.author or ''
    local author = authors[name] or author_column(name, author_cells)
    authors[name] = author
    author_ends[i] = #prefix + #author
    lines[i] = prefix .. author .. ' ' .. (entry and entry.date or '')
  end
  set_lines(buf, lines)

  local hash_start, author_start = 3, 3 + META_HASH_DIGITS + 1
  for i = 1, line_count do
    local entry = state.blame[i]
    local mark = lines[i]:sub(1, 1)
    local mark_hl = mark == '+' and 'GitBlameAdded'
      or mark == '~' and 'GitBlameModified'
      or (mark == '-' and 'GitBlameRemoved') or nil
    if mark_hl then
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, { end_col = 2, hl_group = mark_hl })
    end
    if entry and entry.sha ~= '' then
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, hash_start, {
        end_col = hash_start + META_HASH_DIGITS, hl_group = 'GitBlameHash',
      })
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, author_start, {
        end_col = author_ends[i], hl_group = 'GitBlameAuthor',
      })
      local date_start = author_ends[i] + 1
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, date_start, {
        end_col = date_start + #((entry and entry.date) or ''), hl_group = 'GitBlameDate',
      })
    end
  end
end

--- Draw the content and meta panes. `redraw_only` reuses the cached fetch and blame,
--- so toggling markers costs no git calls at all.
local function render_main(state, redraw_only)
  local cbuf, mbuf = state.bufs.content, state.bufs.meta
  if not vim.api.nvim_buf_is_valid(cbuf) or not vim.api.nvim_buf_is_valid(mbuf) then
    return
  end
  -- keep the reader's position when only the markers change
  local keep = {}
  for name, win in pairs({ meta = state.wins.meta, content = state.wins.content }) do
    if vim.api.nvim_win_is_valid(win) then
      keep[name] = vim.api.nvim_win_get_cursor(win)
    end
  end

  local lines
  if redraw_only then
    -- only what we draw has changed: reuse the cached file, blame and change maps
    lines = state.lines or {}
    vim.api.nvim_buf_clear_namespace(cbuf, ns, 0, -1)
  else
    local path = path_at(state, state.focus)
    local text = git.show_file(state.root, state.focus, path)
    if not text then
      state.changes, state.touched, state.blame = { added = {}, removed = {}, removed_text = {} }, {}, {}
      state.line_count, state.lines = 1, {}
      state.message = 'file did not exist at ' .. short(state.focus) .. ' (' .. path .. ')'
      set_lines(cbuf, { state.message })
      set_lines(mbuf, { '' })
      return
    end
    lines = git.lines(text)
    state.lines = lines
    set_lines(cbuf, lines)
    local ft = vim.filetype.match({ filename = path })
    vim.bo[cbuf].filetype = ft or ''

    state.changes = git.changed_lines(state.root, state.focus, path)
    state.touched = (state.focus == state.head and path == state.rel)
        and git.worktree_touched(state.root, state.focus, state.rel) or {}
    state.blame = git.blame(state.root, state.focus, path) or {}
    state.line_count = #lines
  end

  -- Change markers are sign-column extmarks: they never add or shift a line, so the
  -- meta pane stays line-for-line aligned with the content pane. set_lines() clears
  -- the namespace, so re-rendering replaces them.
  if state.show_changes then
    local function mark(lnum, text, hl, line_hl)
      if lnum >= 1 and lnum <= #lines then
        vim.api.nvim_buf_set_extmark(cbuf, ns, lnum - 1, 0, {
          sign_text = text, sign_hl_group = hl, line_hl_group = line_hl,
        })
      end
    end
    for lnum in pairs(state.changes.added) do
      mark(lnum, '+', 'GitBlameAdded', 'GitBlameAddedLine')
    end
    for lnum in pairs(state.touched) do
      if not state.changes.added[lnum] then
        mark(lnum, '~', 'GitBlameModified', 'GitBlameModifiedLine')
      end
    end
  end

  render_meta(state, #lines)

  local changes = state.changes
  if state.show_changes and next(changes.removed_text) then
    local commit = state.rows[state.index[state.focus]] or git.commit_author_date(state.root, state.focus)
    local deleted_by = {
      { '-  ', 'GitBlameRemoved' },
      { state.focus:sub(1, META_HASH_DIGITS), 'GitBlameHash' },
      { ' ' .. author_column(commit.author, meta_author_cells(config.get())) .. ' ', 'GitBlameAuthor' },
      { commit.date, 'GitBlameDate' },
    }
    for before, deleted in pairs(changes.removed_text) do
      local content_rows, meta_rows = {}, {}
      for i, line in ipairs(deleted) do
        content_rows[i] = { { line:sub(2), 'GitBlameRemovedLine' } }
        meta_rows[i] = deleted_by
      end
      -- Pair the virtual rows without changing file line numbers or blame indices.
      local row = math.max(0, before - 2)
      vim.api.nvim_buf_set_extmark(cbuf, ns, row, 0, { virt_lines = content_rows, virt_lines_above = before == 1 })
      vim.api.nvim_buf_set_extmark(mbuf, ns, row, 0, { virt_lines = meta_rows, virt_lines_above = before == 1 })
    end
  end

  for name, win in pairs({ meta = state.wins.meta, content = state.wins.content }) do
    if vim.api.nvim_win_is_valid(win) and keep[name] then
      local lnum = math.min(keep[name][1], math.max(1, #lines))
      pcall(vim.api.nvim_win_set_cursor, win, { lnum, keep[name][2] })
    end
  end
end

local function render_all(state)
  render_graph(state)
  render_main(state)
end

-- ---------------------------------------------------------------- data

local function remember_focus(state)
  if state.focus then
    table.insert(state.focus_back, state.focus)
    state.focus_forward = {}
  end
end

local function rebuild(state)
  local parsed = graph.parse(git.log_graph(state.root, state.rel, state.follow) or '')
  state.rows = parsed.rows
  state.counts = git.change_counts(state.root, state.rel, state.follow)
  state.art_width = parsed.art_width
  state.index = graph.index(parsed.rows)
  local added_width, removed_width = 2, 2 -- one sign and at least one digit
  for sha in pairs(state.index) do
    local count = state.counts[sha]
    if count then
      added_width = math.max(added_width, 1 + #tostring(count.added))
      removed_width = math.max(removed_width, 1 + #tostring(count.removed))
    end
  end
  state.count_widths = { added_width, removed_width }
  state.children = graph.children(parsed.rows)
  state.paths = git.paths_at(state.root, state.rel, state.follow)
  state.head = git.head_file_commit(state.root, state.rel, state.follow)
  if not state.focus or not state.index[state.focus] then
    local sha = state.head or next(state.index)
    if sha ~= state.focus then
      remember_focus(state)
      state.focus = sha
    end
  end
end

-- ---------------------------------------------------------------- actions

local function set_focus(state, sha, from_history)
  if sha == state.focus then
    return say(state, 'already on ' .. short(sha))
  end
  if not from_history then
    remember_focus(state)
  end
  state.focus = sha
  render_all(state)
  local where = state.index[sha] and '' or ' (outside the listed history)'
  return say(state, 'focus ' .. short(sha) .. where)
end

local function jump_focus(state, from, to, direction)
  local sha = table.remove(state[from])
  if not sha then
    return say(state, 'no ' .. direction .. ' focused commit')
  end
  table.insert(state[to], state.focus)
  return set_focus(state, sha, true)
end

function M.focus_commit(sha)
  local state, err = current()
  if not state then
    return fail(err)
  end
  if not sha then
    return fail('no commit given')
  end
  return set_focus(state, sha)
end

--- Focus the parent of the focus commit (works from any pane).
function M.focus_parent()
  local state, err = current()
  if not state then
    return fail(err)
  end
  local row = state.index[state.focus] and state.rows[state.index[state.focus]]
  local parents = row and row.parents or {}
  if #parents == 0 then
    -- `git log -- <file>` simplifies history, so the oldest listed commit shows no
    -- parent even though the repository has one: ask git before calling it a root.
    parents = git.parents(state.root, state.focus)
  end
  for _, parent in ipairs(parents) do
    if state.index[parent] then
      return set_focus(state, parent)
    end
  end
  if #parents == 0 then
    return say(state, 'root commit: no parent')
  end
  return say(state, 'parent commit is not part of this file history')
end

--- Focus the child of the focus commit (works from any pane).
function M.focus_child()
  local state, err = current()
  if not state then
    return fail(err)
  end
  local child
  for _, sha in ipairs(state.children[state.focus] or {}) do
    if state.index[sha] and not child then
      child = sha
    end
  end
  if not child then
    return say(state, 'already at the newest commit of this file: no child')
  end
  return set_focus(state, child)
end

function M.toggle_changes()
  local state, err = current()
  if not state then
    return fail(err)
  end
  state.show_changes = not state.show_changes
  render_main(state, true) -- the data is unchanged; only the drawing is
  return say(state, 'change markers: ' .. (state.show_changes and 'on' or 'off'))
end

function M.toggle_follow()
  local state, err = current()
  if not state then
    return fail(err)
  end
  state.follow = not state.follow
  rebuild(state) -- keeps the focused commit when it is still listed
  render_all(state)
  return say(state, '--follow: ' .. (state.follow and 'on' or 'off'))
end

--- <CR> focuses the graph row or the commit that last changed the current file line.
function M.select()
  local state, err = current()
  if not state then
    return fail(err)
  end
  local win = vim.api.nvim_get_current_win()
  if win == state.wins.graph then
    local row = state.rows[vim.api.nvim_win_get_cursor(win)[1]]
    if not row or row.kind ~= 'commit' then
      return say(state, 'no commit on this row')
    end
    return set_focus(state, row.sha)
  elseif win == state.wins.meta or win == state.wins.content then
    return M.focus_line_commit()
  end
  return say(state, 'nothing to select here')
end

--- Focus the commit that last changed the line under the cursor.
function M.focus_line_commit()
  local state, err = current()
  if not state then
    return fail(err)
  end
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local entry = state.blame[lnum]
  if not entry or entry.sha == '' or entry.sha:match('^0+$') then
    return say(state, 'line ' .. lnum .. ' is not committed yet')
  end
  return set_focus(state, entry.sha)
end

--- Start lines of the focus commit's change blocks: added lines, lines the working tree
--- changed since that commit, and removal points, with runs of adjacent lines merged
--- into one stop, so `]c` walks hunks instead of single lines.
local function change_blocks(state)
  local limit = math.max(1, state.line_count or 0)
  local seen, lines = {}, {}
  for _, counts in ipairs({ state.changes.added, state.touched, state.changes.removed }) do
    for position in pairs(counts or {}) do
      -- a removal after the last line of the file belongs to that last line
      local lnum = math.min(position, limit)
      if lnum >= 1 and not seen[lnum] then
        seen[lnum] = true
        lines[#lines + 1] = lnum
      end
    end
  end
  table.sort(lines)
  local blocks, previous = {}, nil
  for _, lnum in ipairs(lines) do
    if not previous or lnum > previous + 1 then
      blocks[#blocks + 1] = lnum
    end
    previous = lnum
  end
  return blocks
end

--- Jump both file panes to the next (step > 0) or previous (step < 0) change block of
--- the focus commit. A run of adjacent changed lines is one stop, so `]c` from the first
--- line of a two-line addition goes to the next block, not to its second line. No wrapping.
local function jump_change(state, step)
  local win = state.wins.content
  if not vim.api.nvim_win_is_valid(win) then
    return fail('the content pane is gone')
  end
  local changes = change_blocks(state)
  if #changes == 0 then
    return say(state, 'the focus commit changed no lines in this view')
  end
  local source = vim.api.nvim_get_current_win() == state.wins.meta and state.wins.meta or win
  local cursor_line = vim.api.nvim_win_get_cursor(source)[1]
  local target, index
  if step > 0 then
    for i, lnum in ipairs(changes) do
      if lnum > cursor_line then
        target, index = lnum, i
        break
      end
    end
    if not target then
      return say(state, 'no next change of ' .. short(state.focus))
    end
  else
    for i = #changes, 1, -1 do
      if changes[i] < cursor_line then
        target, index = changes[i], i
        break
      end
    end
    if not target then
      return say(state, 'no previous change of ' .. short(state.focus))
    end
  end
  pcall(vim.api.nvim_win_set_cursor, win, { target, 0 })
  -- the meta pane is scroll-bound, but move its cursor too so both panes mark the line
  if vim.api.nvim_win_is_valid(state.wins.meta) then
    pcall(vim.api.nvim_win_set_cursor, state.wins.meta, { target, 0 })
  end
  return say(state, ('change %d of %d, line %d'):format(index, #changes, target))
end

--- `]c` in either file pane.
function M.next_change()
  local state, err = current()
  if not state then
    return fail(err)
  end
  return jump_change(state, 1)
end

--- `[c` in either file pane.
function M.prev_change()
  local state, err = current()
  if not state then
    return fail(err)
  end
  return jump_change(state, -1)
end

local function setup_diff(buf, lines, root, paths)
  vim.wo.foldmethod = 'manual'
  vim.wo.foldminlines = 0
  vim.wo.foldenable = true
  vim.cmd('normal! zE')
  local hunks, sections, first = {}, {}, nil
  for i = 1, #lines + 1 do
    local line = lines[i]
    local header = line and line:match('^@@ %-%d')
    local file_header = line and line:match('^diff %-%-git ')
    if file_header then sections[#sections + 1] = i end
    if not line or header or file_header then
      if first then
        hunks[#hunks + 1] = { first, i - 1 }
        vim.cmd(('%d,%dfold'):format(first, i - 1))
      end
      first = header and i or nil
    end
  end
  vim.cmd('normal! zR')

  local function jump(step)
    local cursor = vim.api.nvim_win_get_cursor(0)[1]
    local first_index, last_index = 1, #hunks
    if step < 0 then
      first_index, last_index = last_index, first_index
    end
    for i = first_index, last_index, step do
      local hunk = hunks[i]
      if (step > 0 and hunk[1] > cursor) or (step < 0 and hunk[2] < cursor) then
        vim.api.nvim_win_set_cursor(0, { hunk[1], 0 })
        return
      end
    end
  end
  bind(buf, 'next_change', function() jump(1) end, 'next diff hunk')
  bind(buf, 'prev_change', function() jump(-1) end, 'previous diff hunk')
  bind(buf, 'open_commit', function()
    local cursor = vim.api.nvim_win_get_cursor(0)[1]
    for i = #sections, 1, -1 do
      if sections[i] <= cursor then
        local path = #sections == #paths and paths[i]
        if not path then return fail('could not identify the file under the cursor') end
        local file = root .. '/' .. path
        if vim.fn.filereadable(file) ~= 1 then
          return fail('file is not available in the working tree: ' .. path)
        end
        vim.cmd('tabnew')
        vim.api.nvim_win_set_buf(0, vim.fn.bufadd(file))
        if not M.open(file, true) then vim.cmd('tabclose') end
        return
      end
    end
    return say(nil, 'no changed file under the cursor')
  end, 'open blame for this changed file')
end

--- Open the commit header and full repository diff in a new tabpage.
function M.open_commit(sha)
  local state, err = current()
  if not state then
    return fail(err)
  end
  sha = sha or state.focus
  local header = git.lines(git.commit_text(state.root, sha) or ('no such commit: ' .. sha))
  local patch, paths, diff_err = git.commit_diff(state.root, sha)
  if not patch then return fail(diff_err) end
  local diff = git.lines(patch)

  vim.cmd('tabnew')
  seq = seq + 1
  local hbuf = scratch_buf('gitblame://' .. seq .. '/commit')
  set_lines(hbuf, header)
  vim.bo[hbuf].filetype = 'gitcommit'
  vim.api.nvim_win_set_buf(0, hbuf)
  vim.wo.scrollbind = false -- the diff split inherits this window's options
  vim.cmd('belowright split')
  local dbuf = scratch_buf('gitblame://' .. seq .. '/diff')
  set_lines(dbuf, diff)
  vim.bo[dbuf].filetype = 'diff'
  vim.api.nvim_win_set_buf(0, dbuf)
  setup_diff(dbuf, diff, state.root, paths)
  pcall(vim.api.nvim_win_set_cursor, 0, { 1, 0 })

  local close = config.get().keymaps.close
  if close and close ~= '' then
    for _, buf in ipairs({ hbuf, dbuf }) do
      vim.keymap.set('n', close, function()
        pcall(vim.cmd, 'tabclose')
      end, { buffer = buf, nowait = true, silent = true, desc = 'gitblame: close commit tab' })
    end
  end
  return say(state, 'opened commit ' .. short(sha))
end

--- `o`: open the commit under the cursor, falling back to the focused commit.
function M.open_commit_at_cursor()
  local state, err = current()
  if not state then
    return fail(err)
  end
  local win = vim.api.nvim_get_current_win()
  local sha = state.focus
  if win == state.wins.meta or win == state.wins.content then
    local entry = state.blame[vim.api.nvim_win_get_cursor(0)[1]]
    if entry and entry.sha ~= '' then
      sha = entry.sha
    end
  elseif win == state.wins.graph then
    -- in the graph pane, `o` shows the commit on the row under the cursor
    local row = state.rows[vim.api.nvim_win_get_cursor(0)[1]]
    if row and row.kind == 'commit' then
      sha = row.sha
    end
  end
  return M.open_commit(sha)
end

function M.refresh()
  local state, err = current()
  if not state then
    return fail(err)
  end
  rebuild(state)
  render_all(state)
  return say(state, 'refreshed ' .. state.rel)
end

-- ---------------------------------------------------------------- open/close

--- Open (or replace) the blame view. `path` nil or '' means the current buffer's file.
function M.open(path, literal_path)
  local opts = config.get()
  config.set_highlights()

  local file = path
  if not file or file == '' then
    file = vim.api.nvim_buf_get_name(0)
    if file == '' then
      return fail('the current buffer has no file name')
    end
  end
  file = vim.fn.fnamemodify(literal_path and file or vim.fn.expand(file), ':p')
  if vim.fn.filereadable(file) ~= 1 then
    return fail('not a readable file: ' .. file)
  end
  local root = git.root_for(file)
  if not root then
    return fail('not inside a git repository: ' .. file)
  end
  local rel = git.tracked_path(file)
  if not rel then
    return fail('not tracked by git: ' .. file)
  end

  local state = {
    root = root, rel = rel, abs = file, follow = opts.follow, show_changes = opts.show_changes,
    focus_back = {}, focus_forward = {},
  }
  local built, build_err = pcall(rebuild, state)
  if not built then
    return fail('could not read git history: ' .. tostring(build_err))
  end
  if not state.focus then
    return fail('no committed history for ' .. rel)
  end
  if state_for() then
    M.close()
  end

  local tabpage = vim.api.nvim_get_current_tabpage()
  local orig_win = vim.api.nvim_get_current_win()
  local orig_buf = vim.api.nvim_win_get_buf(orig_win)
  local saved = { win = {} }
  for _, name in ipairs(WINOPTS) do
    saved.win[name] = vim.api.nvim_get_option_value(name, { win = orig_win })
  end

  -- graph pane above the current window; meta pane to the left of it
  vim.cmd('leftabove split')
  local graph_win = vim.api.nvim_get_current_win()
  local content_win = orig_win
  vim.api.nvim_set_current_win(content_win)
  vim.cmd('vsplit')
  local meta_win = vim.api.nvim_get_current_win()

  seq = seq + 1
  state.tabpage, state.orig_win, state.orig_buf, state.saved = tabpage, orig_win, orig_buf, saved
  state.wins = { graph = graph_win, meta = meta_win, content = content_win }
  state.bufs = {
    graph = scratch_buf('gitblame://' .. seq .. '/graph'),
    meta = scratch_buf('gitblame://' .. seq .. '/meta'),
    content = scratch_buf('gitblame://' .. seq .. '/content'),
  }
  -- scrollopt is global, so the first view owns the snapshot until the last closes.
  if not next(views) then
    saved_scrollopt = vim.opt_global.scrollopt:get()
    vim.opt_global.scrollopt = { 'ver', 'jump' }
  end
  views[tabpage] = state

  local ready, render_err = pcall(function()
    vim.api.nvim_win_set_buf(graph_win, state.bufs.graph)
    vim.api.nvim_win_set_buf(meta_win, state.bufs.meta)
    vim.api.nvim_win_set_buf(content_win, state.bufs.content)

    wset(graph_win, {
      wrap = false, number = false, relativenumber = false, foldcolumn = '0', signcolumn = 'no',
      cursorline = true, spell = false, list = false, winfixheight = true, foldenable = false,
      scrolloff = 1, winfixbuf = vim.fn.exists('+winfixbuf') == 1 and true or false,
    })
    wset(meta_win, {
      scrollbind = true, scrolloff = 0, wrap = false, number = false, relativenumber = false,
      foldcolumn = '0', signcolumn = 'no', cursorline = true, spell = false, list = false,
      winfixwidth = true, foldenable = false, colorcolumn = '',
    })
    wset(content_win, {
      scrollbind = true, scrolloff = 0, wrap = false, number = true, relativenumber = false,
      signcolumn = 'yes', cursorline = true, spell = false, list = false, foldenable = false,
      foldcolumn = saved.win.foldcolumn,
    })

    pcall(vim.api.nvim_win_set_height, graph_win, graph_height(state))
    pcall(vim.api.nvim_win_set_width, meta_win, opts.meta_width)
    render_all(state)
    bind_all(state)
  end)
  if not ready then
    M.close(tabpage)
    return fail('could not render git history: ' .. tostring(render_err))
  end

  state.augroup = vim.api.nvim_create_augroup('gitblame' .. seq, { clear = true })
  vim.api.nvim_create_autocmd({ 'CursorMoved', 'BufEnter' }, {
    buffer = state.bufs.graph,
    group = state.augroup,
    callback = function()
      highlight_connection(state, vim.api.nvim_win_get_cursor(0)[1])
    end,
  })
  vim.api.nvim_create_autocmd('WinClosed', {
    group = state.augroup,
    callback = function(ev)
      local closed = tonumber(ev.match)
      if state.closing or views[tabpage] ~= state then
        return
      end
      if closed == graph_win or closed == meta_win or closed == content_win then
        M.close(tabpage)
      end
    end,
  })
  -- open where the reading happens: the content pane, at its first line
  vim.api.nvim_set_current_win(content_win)
  pcall(vim.api.nvim_win_set_cursor, content_win, { 1, 0 })
  pcall(vim.api.nvim_win_set_cursor, meta_win, { 1, 0 })
  return true, state
end

--- Tear the view down and put the user's window back the way it was.
function M.close(tabpage)
  local state = state_for(tabpage or vim.api.nvim_get_current_tabpage())
  if not state then
    return fail('no gitblame view in this tabpage')
  end
  state.closing = true
  views[state.tabpage] = nil
  close_help(state) -- the shortcut popup belongs to the view, not to the tabpage
  if state.augroup then
    pcall(vim.api.nvim_del_augroup_by_id, state.augroup)
  end

  local content_win = state.wins.content
  if vim.api.nvim_win_is_valid(content_win) then
    if vim.api.nvim_buf_is_valid(state.orig_buf) then
      pcall(vim.api.nvim_win_set_buf, content_win, state.orig_buf)
    end
    for name, value in pairs(state.saved.win) do
      pcall(vim.api.nvim_set_option_value, name, value, { win = content_win })
    end
  end
  for _, name in ipairs({ 'graph', 'meta' }) do
    local win = state.wins[name]
    if vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
  if not next(views) and saved_scrollopt then
    vim.opt_global.scrollopt = saved_scrollopt
    saved_scrollopt = nil
  end
  for _, buf in pairs(state.bufs) do
    if vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end
  if vim.api.nvim_win_is_valid(state.orig_win) then
    pcall(vim.api.nvim_set_current_win, state.orig_win)
  end
  return true
end

-- ---------------------------------------------------------------- keymaps

bind = function(buf, key_name, fn, desc)
  local key = config.get().keymaps[key_name]
  if not key or key == '' or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  vim.keymap.set('n', key, fn, { buffer = buf, nowait = true, silent = true,
    desc = 'gitblame: ' .. desc })
end

--- Close the shortcut popup of this view, if it is open. The view owns the popup: it
--- must not outlive `q`, a reopen, or a second `h`.
close_help = function(state)
  local win = state.help_win
  state.help_win = nil
  if win and vim.api.nvim_win_is_valid(win) then
    pcall(vim.api.nvim_win_close, win, true)
  end
end

local function show_help(state)
  close_help(state) -- one popup per view: another `h` replaces the open one
  local prefix, entries = 'gitblame: ', {}
  for _, buf in pairs(state.bufs) do
    for _, map in ipairs(vim.api.nvim_buf_get_keymap(buf, 'n')) do
      if map.desc and vim.startswith(map.desc, prefix) then
        entries[map.lhs .. '  ' .. map.desc:sub(#prefix + 1)] = true
      end
    end
  end
  local lines = vim.tbl_keys(entries)
  table.sort(lines)
  lines[#lines + 1] = ''
  lines[#lines + 1] = '<Esc>  close this popup'

  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end
  width = math.max(1, math.min(width, vim.o.columns - 2))
  local rows = vim.o.lines - vim.o.cmdheight
  local height = math.max(1, math.min(#lines, rows - 2))
  local buf = scratch_buf('gitblame://help/' .. tostring(state.tabpage))
  set_lines(buf, lines)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor', style = 'minimal', border = 'rounded', title = ' GitBlame shortcuts ',
    width = width, height = height,
    col = math.floor((vim.o.columns - width - 2) / 2),
    row = math.max(0, math.floor((rows - height - 2) / 2)),
  })
  wset(win, { scrollbind = false, wrap = true })
  state.help_win = win

  local function close()
    close_help(state)
  end
  bind(buf, 'close', close, 'close this popup')
  vim.keymap.set('n', '<Esc>', close, { buffer = buf, nowait = true, silent = true })
end

bind_all = function(state)
  -- Shared mappings are available in all three panes.
  for _, buf in pairs(state.bufs) do
    bind(buf, 'parent', M.focus_parent, 'focus parent commit')
    bind(buf, 'child', M.focus_child, 'focus child commit')
    bind(buf, 'toggle_changes', M.toggle_changes, 'toggle change markers and deleted lines')
    bind(buf, 'toggle_follow', M.toggle_follow, 'toggle --follow (rename tracking)')
    bind(buf, 'help', function()
      show_help(state)
    end, 'show this popup')
    -- wrapped so the keymap callback's argument is never taken for a tabpage id
    bind(buf, 'close', function()
      return M.close()
    end, 'close the blame view')
  end
  bind(state.bufs.graph, 'select', M.select, 'focus the commit under the cursor (graph)')
  bind(state.bufs.graph, 'jump_to_focus', function()
    local line = state.index[state.focus]
    if not line then
      return say(state, 'the focused commit is outside the listed history')
    end
    vim.api.nvim_win_set_cursor(state.wins.graph, { line, 0 })
    highlight_connection(state, line)
  end, 'jump to the focused commit (graph)')
  bind(state.bufs.graph, 'copy_hash', function()
    local row = state.rows[vim.api.nvim_win_get_cursor(state.wins.graph)[1]]
    if not row or row.kind ~= 'commit' then
      return say(state, 'no commit on this row')
    end
    vim.fn.setreg('"', row.sha, 'v')
    if vim.fn.has('clipboard') == 1 and vim.fn.setreg('+', row.sha, 'v') == 0 then
      return say(state, 'copied ' .. short(row.sha) .. ' to the clipboard')
    end
    return say(state, 'yanked ' .. short(row.sha) .. ' into the unnamed register')
  end, 'copy the full commit hash (graph)')
  bind(state.bufs.graph, 'open_commit', M.open_commit_at_cursor, 'show the full commit')
  for _, buf in ipairs({ state.bufs.meta, state.bufs.content }) do
    bind(buf, 'select', M.select, 'focus the commit of this line (left/content)')
    bind(buf, 'open_commit', M.open_commit_at_cursor, 'show the full commit')
    bind(buf, 'next_change', M.next_change, 'next change block (left/content)')
    bind(buf, 'prev_change', M.prev_change, 'previous change block (left/content)')
    bind(buf, 'focus_back', function()
      jump_focus(state, 'focus_back', 'focus_forward', 'previous')
    end, 'go back in commit focus history (left/content)')
    bind(buf, 'focus_forward', function()
      jump_focus(state, 'focus_forward', 'focus_back', 'next')
    end, 'go forward in commit focus history (left/content)')
  end
end

return M
