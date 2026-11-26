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
local views = {} -- tabpage id -> view state
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

local bind_all -- forward declared; defined with the keymaps below

local function path_at(state, sha)
  return state.paths[sha] or state.rel
end

-- ---------------------------------------------------------------- rendering

local function render_graph(state)
  local opts = config.get()
  local buf, win = state.bufs.graph, state.wins.graph
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local lines, focus_row = {}, nil
  for i, row in ipairs(state.rows) do
    local art = row.art .. string.rep(' ', state.art_width - #row.art)
    if row.kind == 'commit' then
      local focused = row.sha == state.focus
      if focused then
        focus_row = i
      end
      lines[i] = (focused and opts.focus_sign or ' ') .. ' ' .. art .. ' '
        .. short(row.sha) .. ' ' .. row.subject
    else
      lines[i] = '  ' .. art
    end
  end
  set_lines(buf, lines)

  local art_start, hash_start
  for i, row in ipairs(state.rows) do
    art_start = 2
    hash_start = art_start + state.art_width + 1
    vim.api.nvim_buf_set_extmark(buf, ns, i - 1, art_start, {
      end_col = art_start + state.art_width,
      hl_group = 'GitBlameGraph',
    })
    if row.kind == 'commit' then
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, hash_start, {
        end_col = hash_start + #short(row.sha),
        hl_group = 'GitBlameHash',
      })
      if row.sha == state.focus then
        vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, { line_hl_group = 'GitBlameFocus' })
        vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, { end_col = 1, hl_group = 'GitBlameIndicator' })
      end
    end
  end

  if focus_row and vim.api.nvim_win_is_valid(win) then
    pcall(vim.api.nvim_win_set_cursor, win, { focus_row, 0 })
  end
end

local function render_meta(state, line_count)
  local opts = config.get()
  local buf = state.bufs.meta
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local lines = {}
  for i = 1, line_count do
    local entry = state.blame[i]
    local mark = ' ' -- the change column; highlighted in the pass below
    if state.show_changes then
      if state.changes.added[i] then
        mark = '+'
      elseif state.touched[i] then
        mark = '~'
      elseif state.changes.removed[i] then
        mark = '-' .. state.changes.removed[i]
      end
    end
    local sha = entry and entry.sha or ''
    local hash = sha ~= '' and sha:sub(1, opts.hash_length) or string.rep('-', opts.hash_length)
    if sha ~= '' and sha:match('^0+$') then
      hash = 'WORKTREE'
    end
    lines[i] = string.format('%-2s %-' .. opts.hash_length .. 's %-' .. opts.author_width
      .. 's %s', mark, hash, entry and entry.author or '', entry and entry.date or '')
  end
  set_lines(buf, lines)

  local hash_start, author_start = 3, 3 + opts.hash_length + 1
  local date_start = author_start + opts.author_width + 1
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
        end_col = hash_start + opts.hash_length, hl_group = 'GitBlameHash',
      })
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, author_start, {
        end_col = author_start + opts.author_width, hl_group = 'GitBlameAuthor',
      })
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, date_start, {
        end_col = date_start + #((entry and entry.date) or ''), hl_group = 'GitBlameDate',
      })
    end
  end
end

local function render_main(state)
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

  local path = path_at(state, state.focus)
  local text, err = git.show_file(state.root, state.focus, path)
  if not text then
    state.changes, state.touched, state.blame = { added = {}, removed = {} }, {}, {}
    state.line_count = 1
    state.message = 'file did not exist at ' .. short(state.focus) .. ' (' .. path .. ')'
    set_lines(cbuf, { state.message })
    set_lines(mbuf, { '' })
    return
  end

  local lines = git.lines(text)
  set_lines(cbuf, lines)
  local ft = vim.filetype.match({ filename = path })
  vim.bo[cbuf].filetype = ft or ''

  state.changes = git.changed_lines(state.root, state.focus, path)
  state.touched = (state.focus == state.head and path == state.rel)
      and git.worktree_touched(state.root, state.focus, state.rel) or {}
  state.blame = git.blame(state.root, state.focus, path) or {}
  state.line_count = #lines

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

  for name, win in pairs({ meta = state.wins.meta, content = state.wins.content }) do
    if vim.api.nvim_win_is_valid(win) and keep[name] then
      local lnum = math.min(keep[name][1], math.max(1, #lines))
      pcall(vim.api.nvim_win_set_cursor, win, { lnum, keep[name][2] })
    end
  end
  if err then
    state.message = err
  end
end

local function render_all(state)
  render_graph(state)
  render_main(state)
end

-- ---------------------------------------------------------------- data

local function rebuild(state)
  local parsed = graph.parse(git.log_graph(state.root, state.rel, state.follow) or '')
  state.rows = parsed.rows
  state.art_width = parsed.art_width
  state.index = graph.index(parsed.rows)
  state.children = graph.children(parsed.rows)
  state.paths = git.paths_at(state.root, state.rel, state.follow)
  state.head = git.head_file_commit(state.root, state.rel, state.follow)
  if not state.focus or not state.index[state.focus] then
    state.focus = state.head or next(state.index)
  end
end

-- ---------------------------------------------------------------- actions

local function set_focus(state, sha)
  if sha == state.focus then
    return say(state, 'already on ' .. short(sha))
  end
  state.focus = sha
  render_all(state)
  local where = state.index[sha] and '' or ' (outside the listed history)'
  return say(state, 'focus ' .. short(sha) .. where)
end

function M.focus_commit(sha)
  local state, err = current()
  if not state then
    return fail(err)
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
  render_main(state)
  return say(state, 'change markers: ' .. (state.show_changes and 'on' or 'off'))
end

function M.toggle_follow()
  local state, err = current()
  if not state then
    return fail(err)
  end
  state.follow = not state.follow
  local before = state.focus
  rebuild(state)
  if state.index[before] then
    state.focus = before
  end
  render_all(state)
  return say(state, '--follow: ' .. (state.follow and 'on' or 'off'))
end

--- <CR> in the graph pane focuses the row; in the meta pane, the line's commit.
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
  elseif win == state.wins.meta then
    return M.focus_line_commit()
  end
  return say(state, 'nothing to select here')
end

--- Focus the commit that last changed the line under the cursor (meta pane).
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

--- Content lines the focus commit touched, sorted: added lines, lines the working tree
--- changed since that commit, and the positions where lines were removed.
local function change_lines(state)
  local seen, out = {}, {}
  for _, counts in ipairs({ state.changes.added, state.touched, state.changes.removed }) do
    for lnum in pairs(counts or {}) do
      if not seen[lnum] and lnum >= 1 and lnum <= (state.line_count or 0) then
        seen[lnum] = true
        out[#out + 1] = lnum
      end
    end
  end
  table.sort(out)
  return out
end

--- Jump the content pane to the next (step > 0) or previous (step < 0) change of the
--- focus commit. No wrapping, like Vim's ]c / [c.
local function jump_change(state, step)
  local win = state.wins.content
  if not vim.api.nvim_win_is_valid(win) then
    return fail('the content pane is gone')
  end
  local changes = change_lines(state)
  if #changes == 0 then
    return say(state, 'the focus commit changed no lines in this view')
  end
  local cursor_line = vim.api.nvim_win_get_cursor(win)[1]
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

--- `]c` in the content pane.
function M.next_change()
  local state, err = current()
  if not state then
    return fail(err)
  end
  return jump_change(state, 1)
end

--- `[c` in the content pane.
function M.prev_change()
  local state, err = current()
  if not state then
    return fail(err)
  end
  return jump_change(state, -1)
end

--- Open the commit header + file diff in a new tabpage.
function M.open_commit(sha)
  local state, err = current()
  if not state then
    return fail(err)
  end
  sha = sha or state.focus
  local path = path_at(state, sha)
  local header = git.lines(git.commit_text(state.root, sha) or ('no such commit: ' .. sha))
  local diff = git.lines(git.commit_diff(state.root, sha, path) or '')

  vim.cmd('tabnew')
  seq = seq + 1
  local hbuf = scratch_buf('gitblame://' .. seq .. '/commit')
  set_lines(hbuf, header)
  vim.bo[hbuf].filetype = 'gitcommit'
  vim.api.nvim_win_set_buf(0, hbuf)
  vim.cmd('belowright split')
  local dbuf = scratch_buf('gitblame://' .. seq .. '/diff')
  set_lines(dbuf, diff)
  vim.bo[dbuf].filetype = 'diff'
  vim.api.nvim_win_set_buf(0, dbuf)
  pcall(vim.api.nvim_win_set_cursor, 0, { 1, 0 })

  local close = config.get().keymaps.close
  if close and close ~= '' then
    for _, buf in ipairs({ hbuf, dbuf }) do
      vim.keymap.set('n', close, function()
        pcall(vim.cmd, 'tabclose')
      end, { buffer = buf, nowait = true, silent = true, desc = 'gitblame: close commit tab' })
    end
  end
  state.commit_tabs = state.commit_tabs or {}
  table.insert(state.commit_tabs, vim.api.nvim_get_current_tabpage())
  return say(state, 'opened commit ' .. short(sha))
end

--- `o`: full commit for the line under the cursor (meta) or the focus commit.
function M.open_commit_at_cursor()
  local state, err = current()
  if not state then
    return fail(err)
  end
  local win = vim.api.nvim_get_current_win()
  local sha = state.focus
  if win == state.wins.meta then
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
function M.open(path)
  local opts = config.get()
  config.set_highlights()

  local file = path
  if not file or file == '' then
    file = vim.api.nvim_buf_get_name(0)
    if file == '' then
      return fail('the current buffer has no file name')
    end
  end
  file = vim.fn.fnamemodify(vim.fn.expand(file), ':p')
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

  if state_for() then
    M.close()
  end

  local tabpage = vim.api.nvim_get_current_tabpage()
  local orig_win = vim.api.nvim_get_current_win()
  local orig_buf = vim.api.nvim_win_get_buf(orig_win)
  local saved = { win = {}, scrollopt = vim.opt_global.scrollopt:get() }
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
  local state = {
    tabpage = tabpage,
    orig_win = orig_win,
    orig_buf = orig_buf,
    saved = saved,
    root = root,
    rel = rel,
    abs = file,
    follow = opts.follow,
    show_changes = opts.show_changes,
    wins = { graph = graph_win, meta = meta_win, content = content_win },
    bufs = {
      graph = scratch_buf('gitblame://' .. seq .. '/graph'),
      meta = scratch_buf('gitblame://' .. seq .. '/meta'),
      content = scratch_buf('gitblame://' .. seq .. '/content'),
    },
    blame = {},
    changes = { added = {}, removed = {} },
    touched = {},
  }
  views[tabpage] = state

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
  -- vertical-only scroll binding keeps the two panes line aligned
  pcall(function()
    vim.opt_global.scrollopt = { 'ver', 'jump' }
  end)

  pcall(vim.api.nvim_win_set_height, graph_win,
    math.max(4, math.floor((vim.o.lines - 2) * opts.top_ratio)))
  pcall(vim.api.nvim_win_set_width, meta_win, opts.meta_width)

  local ok, build_err = pcall(rebuild, state)
  if not ok then
    views[tabpage] = nil
    return fail('could not read git history: ' .. tostring(build_err))
  end
  render_all(state)
  bind_all(state)

  state.augroup = vim.api.nvim_create_augroup('gitblame' .. seq, { clear = true })
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
  pcall(function()
    vim.opt_global.scrollopt = state.saved.scrollopt
  end)
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

local function bind(buf, key_name, fn, desc)
  local key = config.get().keymaps[key_name]
  if not key or key == '' or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  vim.keymap.set('n', key, fn, { buffer = buf, nowait = true, silent = true,
    desc = 'gitblame: ' .. desc })
end

bind_all = function(state)
  -- parent/child/toggles/close are available in all three panes
  for _, buf in pairs(state.bufs) do
    bind(buf, 'parent', M.focus_parent, 'focus parent commit')
    bind(buf, 'child', M.focus_child, 'focus child commit')
    bind(buf, 'toggle_changes', M.toggle_changes, 'toggle +/- change markers')
    bind(buf, 'toggle_follow', M.toggle_follow, 'toggle --follow (rename tracking)')
    -- wrapped so the keymap callback's argument is never taken for a tabpage id
    bind(buf, 'close', function()
      return M.close()
    end, 'close the blame view')
  end
  -- `o` is available in all three panes: the commit under the cursor (graph, meta)
  -- or the focused commit (content).
  bind(state.bufs.graph, 'select', M.select, 'focus the commit under the cursor')
  bind(state.bufs.graph, 'open_commit', M.open_commit_at_cursor, 'show the full commit')
  bind(state.bufs.meta, 'select', M.select, 'focus the commit of this line')
  bind(state.bufs.meta, 'open_commit', M.open_commit_at_cursor, 'show the full commit')
  bind(state.bufs.content, 'open_commit', M.open_commit_at_cursor, 'show the full commit')
  -- ]c / [c walk the focus commit's changes inside the content pane
  bind(state.bufs.content, 'next_change', M.next_change, 'next change of the focus commit')
  bind(state.bufs.content, 'prev_change', M.prev_change, 'previous change of the focus commit')
end

return M
