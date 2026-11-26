-- Headless test for the gitblame plugin.
-- Run from the repository root: nvim --headless -u NONE -l nvim/tests/gitblame.lua
--
-- Builds a throwaway git repo (root commit -> rename -> branch + merge -> head commit),
-- opens the blame view and asserts layout, row->commit mapping, navigation, toggles,
-- blame columns and teardown.

local function sh(cmd, cwd)
  local res = vim.system({ '/bin/sh', '-c', cmd }, { text = true, cwd = cwd }):wait()
  if res.code ~= 0 then
    error('command failed: ' .. cmd .. '\n' .. (res.stderr or ''), 2)
  end
  return res.stdout or ''
end

local function out(cmd, cwd)
  return vim.trim(sh(cmd, cwd))
end

local function to_lines(s)
  local t = vim.split(s, '\n', { plain = true })
  if #t > 0 and t[#t] == '' then
    table.remove(t)
  end
  return t
end

-- ------------------------------------------------------------------ fixtures
local here = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local repo_root = vim.fn.fnamemodify(here, ':h:h')
local plugin_dir = repo_root .. '/gitblame'

local sandbox = vim.fn.fnamemodify(vim.fn.tempname(), ':p') .. '-gitblame'
local repo = sandbox .. '/repo'
vim.fn.mkdir(sandbox, 'p')

local setup = [[
set -e
rm -rf "$1"
mkdir -p "$1"
cd "$1"
git init -q -b main .
git config user.email test@example.com
git config user.name Tester
git config commit.gpgsign false
printf 'l1\nl2\nl3\n' > tracked.txt
git add -A
git commit -qm 'root: add tracked'
printf 'l1\nl2\nl3\nl3b\n' > tracked.txt
git commit -qam 'second: add l3b'
git mv tracked.txt renamed.txt
git commit -qm 'rename tracked to renamed'
git checkout -qb feature
printf 'l1\nl2\nl3\nfeature\n' > renamed.txt
git commit -qam 'feature: add line'
git checkout -q main
printf 'l1\nl2\nl3\nmain\n' > renamed.txt
git commit -qam 'main: add line'
git merge feature -m 'merge feature' || true
printf 'l1\nl2\nl3\nmain\nfeature\nresolved\n' > renamed.txt
git add -A
git commit -qm 'merge feature resolved'
printf 'l1\nl2\nl3\nmain\nfeature\nresolved\nextra\n' > renamed.txt
printf 'unrelated\n' > other.txt
git add other.txt
git commit -qam 'add extra line' --author='Head Author <head@example.com>' --date='2024-02-04T12:00:00Z'
printf 'scratch\n' > untracked.txt
]]
assert(vim.system({ '/bin/sh', '-c', setup, 'sh', repo }, { text = true }):wait().code == 0,
  'could not build the test repository')

local function git(...)
  local quoted = {}
  for _, arg in ipairs({ ... }) do
    if arg ~= nil and arg ~= '' then quoted[#quoted + 1] = "'" .. tostring(arg):gsub("'", "'\\''") .. "'" end
  end
  return out('git ' .. table.concat(quoted, ' '), repo)
end

local FILE = 'renamed.txt'
local head = git('log', '-1', '--format=%H', '--', FILE)
local root_commit = git('rev-list', '--max-parents=0', 'HEAD')
local second_commit = git('log', '--format=%H', '--grep', 'second: add l3b', '--', 'tracked.txt')
local rename_commit = git('log', '--format=%H', '--grep', 'rename tracked to renamed', '--', FILE)
local main_commit = git('log', '--format=%H', '--grep', 'main: add line', '--', FILE)
local merge_commit = git('log', '--format=%H', '--merges', '--', FILE)
assert(head ~= '' and root_commit ~= '' and merge_commit ~= '' and main_commit ~= '',
  'test repository is missing an expected commit')

local function list_commits(follow)
  local shas = {}
  for _, sha in ipairs(to_lines(git('log', '--format=%H', follow and '--follow' or '', '--', FILE))) do
    if sha ~= '' then
      shas[#shas + 1] = sha
    end
  end
  return shas
end

local listed = list_commits(false)
local followed = list_commits(true)

-- New-side line numbers the commit added, straight from git.
local function added_lines(rev, path)
  local diff = git('diff', '--no-color', '--unified=0', rev .. '^1', rev, '--', path)
  local added = {}
  for _, line in ipairs(to_lines(diff)) do
    local start, count = line:match('^@@ %-%d+,?%d* %+(%d+),?(%d*) @@')
    if start then
      for i = tonumber(start), tonumber(start) + (tonumber(count) or 1) - 1 do
        added[#added + 1] = i
      end
    end
  end
  return added
end

local head_added = added_lines(head, FILE)
assert(#head_added == 1, 'fixture: the head commit should add exactly one line')

-- ------------------------------------------------------------------- plugin
vim.opt.runtimepath:prepend(plugin_dir)
-- `nvim -l` does not put the runtimepath on package.path, so require() needs a hand
package.path = table.concat({
  plugin_dir .. '/lua/?.lua',
  plugin_dir .. '/lua/?/init.lua',
  package.path,
}, ';')
vim.api.nvim_set_hl(0, 'Comment', { fg = '#778899', italic = true })
vim.cmd('runtime plugin/gitblame.lua')

local notices = {}
vim.notify = function(msg, level)
  notices[#notices + 1] = { msg = msg, level = level }
end

local gb = require('gitblame')
assert(vim.fn.exists(':GitBlame') == 2, ':GitBlame command was not registered')

local function last_notice()
  return notices[#notices] and notices[#notices].msg or ''
end

local function lines(buf)
  return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end

--- Change markers the plugin drew in the content pane (sign-column extmarks).
--- ns -1 means "every namespace", so the test does not need the plugin's private one.
local function markers(buf)
  local found = {}
  for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { details = true })) do
    if mark[4] and mark[4].sign_text then
      found[#found + 1] = { lnum = mark[2] + 1, text = (mark[4].sign_text:gsub('%s+$', '')) }
    end
  end
  table.sort(found, function(a, b)
    return a.lnum < b.lnum
  end)
  return found
end

--- Fire the buffer-local normal-mode mapping `key` as if typed in window `win`.
local function press(win, key)
  vim.api.nvim_set_current_win(win)
  local map = vim.fn.maparg(key, 'n', false, true)
  assert(map and map.callback, 'no normal-mode mapping for ' .. key .. ' in this pane')
  -- call the callback directly: nvim_win_call switches curwin but not curtab, so a
  -- mapping that closes a tabpage (`o` -> commit tab) would hit the wrong tab
  map.callback()
end

local function focus_line(buf)
  for _, line in ipairs(lines(buf)) do
    if line:sub(1, 1) == '>' then
      return line
    end
  end
  return nil
end

--- The graph pane pads the author to author_width cells, like the pane renders it.
local function graph_author(name)
  local width = require('gitblame.config').get().author_width
  return name .. string.rep(' ', width - vim.fn.strdisplaywidth(name))
end
-- --------------------------------------------------------------- error paths
vim.cmd('set lines=50 columns=180')

vim.cmd('enew!')
local ok, err = gb.open()
assert(not ok and err:match('no file name'), 'unnamed buffer must be refused, got: ' .. tostring(err))

local outside = sandbox .. '/outside.txt'
vim.fn.writefile({ 'x' }, outside)
ok, err = gb.open(outside)
assert(not ok and err:match('not inside a git repository'), 'files outside a repo must be refused')

ok, err = gb.open(repo .. '/untracked.txt')
assert(not ok and err:match('not tracked by git'), 'untracked files must be refused')

local staged = repo .. '/staged.txt'
vim.fn.writefile({ 'new' }, staged)
git('add', 'staged.txt')
local before_staged = vim.api.nvim_get_current_win()
ok, err = gb.open(staged)
assert(not ok and err:match('no committed history'), 'staged new files must be refused without throwing')
assert(not gb.state() and #vim.api.nvim_list_wins() == 1 and vim.api.nvim_get_current_win() == before_staged,
  'opening an uncommitted file must leave the layout alone')
git('reset', '-q', '--', 'staged.txt')

-- ------------------------------------------------------------------- opening
vim.cmd('edit ' .. vim.fn.fnameescape(repo .. '/' .. FILE))
local orig_win = vim.api.nvim_get_current_win()
local orig_buf = vim.api.nvim_win_get_buf(orig_win)
local orig_scrollbind = vim.api.nvim_get_option_value('scrollbind', { win = orig_win })
local orig_signcolumn = vim.api.nvim_get_option_value('signcolumn', { win = orig_win })

local opened, st = gb.open()
assert(opened and st, ':GitBlame with no argument must use the current buffer')
assert(st.rel == FILE, 'argless open must resolve the current buffer path, got ' .. tostring(st.rel))
assert(#vim.api.nvim_list_wins() == 3, 'the view needs 3 windows (graph, meta, content)')

assert(vim.api.nvim_get_current_win() == st.wins.content,
  'the view must open with the cursor in the content pane')
assert(vim.api.nvim_win_get_cursor(st.wins.content)[1] == 1,
  'the content pane must start at the first line')
assert(vim.api.nvim_win_get_cursor(st.wins.meta)[1] == 1,
  'the meta pane must start at the first line too')

-- Help is available in every pane and does not close or move the blame view.
for _, win in pairs(st.wins) do
  press(win, 'h')
  local popup = vim.api.nvim_get_current_win()
  assert(vim.api.nvim_win_get_config(popup).relative == 'editor', 'h must open a floating popup')
  local shown = table.concat(lines(vim.api.nvim_win_get_buf(popup)), '\n')
  for _, key in ipairs({ '<CR>', 'p', 'P', 't', 'F', 'o', 'f', 'c', ']c', '[c', 'q', 'h' }) do
    assert(('\n' .. shown):find('\n' .. key .. '  ', 1, true), 'help must list ' .. key)
  end
  press(popup, win == st.wins.graph and 'q' or '<Esc>')
  assert(vim.api.nvim_get_current_win() == win and #vim.api.nvim_list_wins() == 3,
    'closing help must return to the pane and leave blame open')
end

vim.api.nvim_set_current_win(st.wins.content)
local function neighbour_buf(direction)
  local nr = vim.fn.winnr(direction)
  assert(nr > 0, 'no window ' .. direction .. ' of the content pane')
  return vim.api.nvim_win_get_buf(vim.fn.win_getid(nr))
end
assert(neighbour_buf('h') == st.bufs.meta, 'meta pane must sit left of the content pane')
assert(neighbour_buf('k') == st.bufs.graph, 'graph pane must sit above the content pane')

-- the top pane fits the history: the smaller of the configured share and the row count
local graph_height = vim.api.nvim_win_get_height(st.wins.graph)
local screen_share = math.floor((vim.o.lines - 2) * 0.34)
assert(graph_height == math.max(3, math.min(screen_share, #st.rows)),
  ('top pane should fit %d rows in a %d-row share: got %d'):format(#st.rows, screen_share, graph_height))
assert(graph_height < screen_share, 'a short history must not waste a third of the screen')

-- commit rows: same set as `git log -- <file>`, first row is the file's HEAD commit
local row_shas, merge_rows = {}, 0
for _, row in ipairs(st.rows) do
  if row.kind == 'commit' then
    row_shas[#row_shas + 1] = row.sha
    if #row.parents > 1 then
      merge_rows = merge_rows + 1
    end
  end
end
assert(#row_shas == #listed,
  ('graph must list %d commits, listed %d'):format(#listed, #row_shas))
local row_set = {}
for _, sha in ipairs(row_shas) do
  row_set[sha] = true
end
for _, sha in ipairs(listed) do
  assert(row_set[sha], 'graph is missing commit ' .. sha:sub(1, 8))
end
assert(row_shas[1] == head, 'the first graph row must be the commit HEAD points at')
assert(merge_rows == 1, 'the merge commit must be listed with two parents')
local graph_text = table.concat(lines(st.bufs.graph), '\n')
assert(graph_text:find('├─┐', 1, true) and graph_text:find('●', 1, true),
  'merge lanes must use connected box-drawing junctions and commit dots')
assert(not vim.api.nvim_get_hl(0, { name = 'GitBlameGraph', link = false }).italic,
  'graph lanes must not inherit italic styling from Comment')

local graph_ns = vim.api.nvim_get_namespaces()['gitblame.graph_selection']
local function selected_graph_rows(sha)
  vim.api.nvim_set_current_win(st.wins.graph)
  vim.api.nvim_win_set_cursor(st.wins.graph, { st.index[sha], 0 })
  vim.api.nvim_exec_autocmds('CursorMoved', { buffer = st.bufs.graph })
  local selected = {}
  for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(st.bufs.graph, graph_ns, 0, -1, {})) do
    selected[mark[2] + 1] = (selected[mark[2] + 1] or 0) + 1
  end
  return selected
end
local selected = selected_graph_rows(merge_commit)
local merge_row = st.index[merge_commit]
assert(selected[merge_row] == 1 and selected[merge_row + 1] >= 3,
  'selecting a merge must highlight its dot and branching connection')
for _, parent in ipairs(st.rows[merge_row].parents) do
  assert(selected[st.index[parent]], 'each visible merge parent must be highlighted')
end
selected = selected_graph_rows(head)
assert(selected[st.index[head]] == 1 and selected[merge_row] == 1 and not selected[merge_row + 1],
  'moving off a merge must clear the old paths and highlight only the new direct connection')
vim.api.nvim_set_current_win(st.wins.content)

-- focus indicator: exactly one row, and it is the HEAD commit's row
local focused = focus_line(st.bufs.graph)
assert(focused, 'a focused commit row is expected on open')
assert(focused:find(head:sub(1, 8), 1, true), 'the default focus must be the HEAD commit of the file')
assert(focused:find('2024-02-04 | +1 -0 | ' .. graph_author('Head Author') .. ' | add extra line', 1, true),
  'the graph must show the date, author, and counts for this file only')
assert(lines(st.bufs.graph)[st.index[merge_commit]]:find('+2 -0 | ' .. graph_author('Tester') .. ' | merge feature resolved', 1, true),
  'merge counts must be relative to the first parent')
assert(vim.api.nvim_win_get_cursor(st.wins.graph)[1] == st.index[head],
  'the graph cursor must sit on the focused row')

-- content pane shows the committed version of the file
local content = lines(st.bufs.content)
local want_content = to_lines(git('show', head .. ':' .. FILE))
assert(#content == #want_content and table.concat(content, '\n') == table.concat(want_content, '\n'),
  'content pane must show the file at the focus commit')

-- meta pane: one row per content row, scroll-locked together
local meta = lines(st.bufs.meta)
assert(#meta == #content, 'meta pane must have one row per content row')
for _, pane in ipairs({ 'meta', 'content' }) do
  assert(vim.api.nvim_get_option_value('scrollbind', { win = st.wins[pane] }),
    pane .. ' pane must be scrollbound')
end
local blame_first = git('blame', '--line-porcelain', head, '--', FILE):match('^(%x+)')
assert(meta[1]:find(blame_first:sub(1, 8), 1, true),
  'first meta row must carry the blame hash of line 1: ' .. meta[1])

-- change markers of the focus commit
local added = head_added[1]
local placed = markers(st.bufs.content)
assert(#placed == 1 and placed[1].lnum == added and placed[1].text == '+',
  'the focus commit must mark its added line with a + sign')
assert(meta[added]:sub(1, 1) == '+', 'meta change column must show + on the added line')
local marked = 0
for _, line in ipairs(meta) do
  if line:sub(1, 1) ~= ' ' then
    marked = marked + 1
  end
end
assert(marked == 1, 'only the added line should be marked, found ' .. marked)

-- scrolling the content pane keeps the meta pane aligned
vim.api.nvim_win_set_cursor(st.wins.content, { #content, 0 })
vim.cmd('normal! zz')
assert(vim.fn.line('w0', st.wins.meta) == vim.fn.line('w0', st.wins.content),
  'meta pane must scroll together with the content pane')

-- ------------------------------------------------ <CR> refocuses the main pane
local rename_row = st.index[rename_commit]
assert(rename_row, 'the rename commit should be listed')
vim.api.nvim_win_set_cursor(st.wins.graph, { rename_row, 0 })
press(st.wins.graph, '<CR>')
assert(st.focus == rename_commit, '<CR> on a graph row must focus that commit')
assert(focus_line(st.bufs.graph):find(rename_commit:sub(1, 8), 1, true),
  'the focus indicator must move to the selected row')
local rename_date = git('show', '-s', '--date=short', '--format=%ad', rename_commit)
assert(focus_line(st.bufs.graph):find(rename_date .. ' | +4 -0 | ' .. graph_author('Tester') .. ' | rename tracked to renamed', 1, true),
  'the graph must show the date and author of each commit')
assert(table.concat(lines(st.bufs.content), '\n')
    == table.concat(to_lines(git('show', rename_commit .. ':' .. FILE)), '\n'),
  'content pane must re-render for the focused commit')

-- ---------------------------------------------------- p / P in every pane
for _, pane in ipairs({ 'graph', 'meta', 'content' }) do
  local before = head
  gb.focus_commit(head)
  press(st.wins[pane], 'p')
  assert(st.focus == merge_commit, pane .. ': p must focus the parent commit')
  assert(focus_line(st.bufs.graph):find(merge_commit:sub(1, 8), 1, true),
    pane .. ': the graph indicator must follow p')
  press(st.wins[pane], 'P')
  assert(st.focus == before, pane .. ': P must focus the child commit again')
end

-- Real keypresses: `-l` never pumps typeahead, so run a nested nvim whose startup script
-- types p / P / t / F / q through the real input parser (`:normal` honours buffer maps).
-- nvim caps -c arguments at 10, so the steps live in a sourced script instead.
local keys = {
  'edit ' .. vim.fn.fnameescape(repo .. '/' .. FILE),
  'GitBlame',
  'normal p',
  'lua io.write("AFTER_P=" .. require("gitblame").state().focus .. "\\n")',
  'normal P',
  'lua io.write("AFTER_CAP_P=" .. require("gitblame").state().focus .. "\\n")',
  'normal t',
  'lua io.write("AFTER_T=" .. tostring(require("gitblame").state().show_changes) .. "\\n")',
  'normal F',
  'lua io.write("AFTER_F=" .. tostring(require("gitblame").state().follow) .. "\\n")',
  'normal q',
  'lua io.write("AFTER_Q=" .. tostring(require("gitblame").state())'
    .. ' .. " wins=" .. tostring(#vim.api.nvim_list_wins()) .. "\\n")',
  'qa!',
}
local keyscript = sandbox .. '/keys.vim'
vim.fn.writefile(keys, keyscript)
local typed = vim.system({
  'nvim', '--headless', '-u', 'NONE',
  '--cmd', 'set rtp+=' .. plugin_dir,
  -- -u NONE skips plugin/ autoload, so source the plugin by hand
  '--cmd', 'runtime plugin/gitblame.lua',
  '--cmd', 'set lines=50 columns=180',
  '-S', keyscript,
}, { text = true }):wait()
local typed_out = typed.stdout or ''
assert(typed.code == 0, 'nested nvim failed: ' .. (typed.stderr or '') .. typed_out)
assert(typed_out:match('AFTER_P=' .. merge_commit), 'typing p must move focus to the parent:\n' .. typed_out)
assert(typed_out:match('AFTER_CAP_P=' .. head), 'typing P must move focus back to the child:\n' .. typed_out)
assert(typed_out:match('AFTER_T=false'), 'typing t must hide the change markers:\n' .. typed_out)
assert(typed_out:match('AFTER_F=true'), 'typing F must enable --follow:\n' .. typed_out)
assert(typed_out:match('AFTER_Q=nil wins=1'), 'typing q must close the view:\n' .. typed_out)

-- parent of the oldest listed commit is not in this file's history: no move
gb.focus_commit(rename_commit)
press(st.wins.graph, 'p')
assert(st.focus == rename_commit, 'focus must not move when the parent is outside the history')
assert(last_notice():match('not part of this file history'), last_notice())

-- ------------------------------------------------------------- t: markers
-- t must work from every pane and never change a line count or the pane alignment.
gb.focus_commit(head)
local content_before, meta_before = #lines(st.bufs.content), #lines(st.bufs.meta)
for _, pane in ipairs({ 'graph', 'meta', 'content' }) do
  press(st.wins[pane], 't')
  assert(st.show_changes == false, pane .. ': t must turn the change markers off')
  assert(#markers(st.bufs.content) == 0, pane .. ': hiding markers must remove the +/- signs')
  for _, line in ipairs(lines(st.bufs.meta)) do
    assert(line:sub(1, 1) == ' ', pane .. ': hiding markers must clear the meta change column')
  end
  assert(#lines(st.bufs.content) == content_before and #lines(st.bufs.meta) == meta_before
      and #lines(st.bufs.meta) == #lines(st.bufs.content),
    pane .. ': toggling markers must keep line counts and pane alignment')
  press(st.wins[pane], 't')
  assert(st.show_changes == true, pane .. ': t must bring the change markers back')
  assert(#markers(st.bufs.content) == 1, pane .. ': t must restore the +/- sign')
  assert(#lines(st.bufs.content) == content_before and #lines(st.bufs.meta) == meta_before
      and #lines(st.bufs.meta) == #lines(st.bufs.content),
    pane .. ': toggling markers back must keep line counts and pane alignment')
end

-- ------------------------------------------------- ]c / [c in the content pane
local merge_added = added_lines(merge_commit, FILE)
assert(#merge_added >= 2, 'fixture: the merge commit should add at least two lines')
gb.focus_commit(merge_commit)
assert(#markers(st.bufs.content) == #merge_added, 'the merge commit must mark every added line')
vim.api.nvim_win_set_cursor(st.wins.content, { 1, 0 })
press(st.wins.content, ']c')
assert(vim.api.nvim_win_get_cursor(st.wins.content)[1] == merge_added[1], ']c must jump to the first change')
assert(vim.api.nvim_win_get_cursor(st.wins.meta)[1] == merge_added[1],
  'the meta pane cursor must follow to the same line')
-- the merge commit adds two adjacent lines: they are one stop, not two
press(st.wins.content, ']c')
assert(vim.api.nvim_win_get_cursor(st.wins.content)[1] == merge_added[1],
  ']c must jump over the rest of an adjacent block instead of to its second line')
assert(last_notice():match('no next change'), last_notice())
press(st.wins.content, '[c')
assert(vim.api.nvim_win_get_cursor(st.wins.content)[1] == merge_added[1],
  '[c must not wrap before the first change block')
assert(last_notice():match('no previous change'), last_notice())

-- --------------------------------------------------------------- F: --follow
-- F must work from every pane and change the *length* of the commit list: the two
-- pre-rename commits only appear with --follow, the merge commit only without it.
local function commit_rows()
  local set, count = {}, 0
  for _, row in ipairs(st.rows) do
    if row.kind == 'commit' then
      set[row.sha] = true
      count = count + 1
    end
  end
  return set, count
end
assert(#followed > #listed, 'fixture: --follow must list more commits than a plain file log')
gb.focus_commit(head)
for _, pane in ipairs({ 'graph', 'meta', 'content' }) do
  press(st.wins[pane], 'F')
  assert(st.follow == true, pane .. ': F must enable --follow')
  local set, count = commit_rows()
  assert(count == #followed and count ~= #listed,
    ('%s: --follow must list %d commits, listed %d'):format(pane, #followed, count))
  local followed_graph = lines(st.bufs.graph)
  assert(followed_graph[st.index[rename_commit]]:find('+0 -0 | ' .. graph_author('Tester') .. ' | rename tracked to renamed', 1, true),
    'following a pure rename must not count the file as new')
  assert(followed_graph[st.index[head]]:find('+1 -0 | ' .. graph_author('Head Author') .. ' | add extra line', 1, true),
    'following renames must still exclude changes to other files')
  assert(set[root_commit] and set[second_commit],
    pane .. ': --follow must list the pre-rename commits')
  assert(st.focus == head, pane .. ': --follow must keep the focused commit')
  assert(table.concat(lines(st.bufs.content), '\n')
      == table.concat(to_lines(git('show', head .. ':' .. FILE)), '\n'),
    pane .. ': content must stay correct after toggling --follow')
  press(st.wins[pane], 'F')
  assert(st.follow == false, pane .. ': F must disable --follow again')
  local back, back_count = commit_rows()
  assert(back_count == #listed,
    ('%s: turning --follow off must list %d commits, listed %d'):format(pane, #listed, back_count))
  assert(not back[root_commit] and back[merge_commit],
    pane .. ': without --follow the pre-rename commits go away and the merge returns')
end

-- with --follow the pre-rename commits are reachable, and the root has no parent
press(st.wins.graph, 'F')
gb.focus_commit(rename_commit)
press(st.wins.graph, 'p')
assert(st.focus == second_commit, 'with --follow, p must reach the commit before the rename')
-- pre-rename commits must be read through the file's old path
assert(table.concat(lines(st.bufs.content), '\n')
    == table.concat(to_lines(git('show', second_commit .. ':tracked.txt')), '\n'),
  'content pane must read a pre-rename commit from its old path')
press(st.wins.graph, 'p')
assert(st.focus == root_commit, 'p must reach the root commit')
assert(table.concat(lines(st.bufs.content), '\n')
    == table.concat(to_lines(git('show', root_commit .. ':tracked.txt')), '\n'),
  'the root commit content must come from the old path too')
press(st.wins.graph, 'p')
assert(st.focus == root_commit, 'a root commit has no parent, focus must stay')
assert(last_notice():match('root commit'), last_notice())
press(st.wins.graph, 'P')
assert(st.focus == second_commit, 'P from the root commit must come back down')
press(st.wins.graph, 'F')
assert(st.follow == false, 'F must leave --follow off again')

-- ------------------------------------------- meta pane: <CR> focus, o commit
gb.focus_commit(head)
local line_of_main = nil
for i, entry in ipairs(st.blame) do
  if entry.sha == main_commit then
    line_of_main = i
  end
end
assert(line_of_main, 'blame must attribute a line to the main-branch commit')
vim.api.nvim_win_set_cursor(st.wins.meta, { line_of_main, 0 })
press(st.wins.meta, '<CR>')
assert(st.focus == main_commit, '<CR> in the meta pane must focus that line commit')
assert(focus_line(st.bufs.graph):find(main_commit:sub(1, 8), 1, true),
  'the top pane indicator must follow a meta-pane focus')
-- main_commit is after the rename, so its content comes from the current path
assert(table.concat(lines(st.bufs.content), '\n')
    == table.concat(to_lines(git('show', main_commit .. ':' .. FILE)), '\n'),
  'content pane must re-render the focused commit')

press(st.wins.content, '<C-o>')
assert(st.focus == head, 'Ctrl-O in content must return to the previous focused commit')
press(st.wins.meta, '<C-i>')
assert(st.focus == main_commit, 'Ctrl-I in the left pane must redo the focus shared with content')
press(st.wins.meta, '<C-o>')
assert(st.focus == head, 'Ctrl-O must also work in the left pane')
press(st.wins.content, '<C-i>')
assert(st.focus == main_commit, 'Ctrl-I must also work in content')
press(st.wins.content, '<C-o>')
vim.api.nvim_win_set_cursor(st.wins.content, { line_of_main, 0 })
press(st.wins.content, '<CR>')
assert(st.focus == main_commit, '<CR> in content must focus the same line commit as the left pane')
press(st.wins.content, '<C-i>')
assert(st.focus == main_commit and last_notice():match('no next focused commit'),
  'a new focus jump must discard forward history')

local tabs_before = #vim.api.nvim_list_tabpages()
press(st.wins.meta, 'o')
local commit_win = vim.api.nvim_get_current_win()
assert(#vim.api.nvim_list_tabpages() == tabs_before + 1, 'o must open the commit in a new tab')
local commit_bufs = vim.api.nvim_list_bufs()
local header_text, diff_text = {}, {}
for _, buf in ipairs(commit_bufs) do
  local name = vim.api.nvim_buf_get_name(buf)
  if name:match('/commit$') then
    header_text = lines(buf)
  elseif name:match('/diff$') then
    diff_text = lines(buf)
  end
end
assert(table.concat(header_text, '\n'):find(main_commit, 1, true),
  'the commit tab must show the commit hash')
assert(table.concat(header_text, '\n'):match('Author:'), 'the commit tab must show the author')
assert(table.concat(diff_text, '\n'):find('@@', 1, true)
    and table.concat(diff_text, '\n'):find('+main', 1, true),
  'the commit tab must show the file diff')
-- the cursor must be in the commit tab for its own `q` mapping to fire
press(commit_win, 'q')
assert(#vim.api.nvim_list_tabpages() == tabs_before, 'q must close the commit tab')

-- `o` in the top pane opens the commit on the row under the cursor, not the focused one
gb.focus_commit(head)
vim.api.nvim_win_set_cursor(st.wins.graph, { st.index[main_commit], 0 })
press(st.wins.graph, 'o')
local graph_commit_win = vim.api.nvim_get_current_win()
assert(#vim.api.nvim_list_tabpages() == tabs_before + 1, 'o in the top pane must open a commit tab')
local graph_header = ''
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
  if vim.api.nvim_buf_get_name(buf):match('/commit$') then
    graph_header = table.concat(lines(buf), '\n')
  end
end
assert(graph_header:find(main_commit, 1, true),
  'o in the top pane must show the commit under the cursor, not the focused commit')
press(graph_commit_win, 'q')
assert(#vim.api.nvim_list_tabpages() == tabs_before, 'q must close the commit tab opened from the top pane')

press(st.wins.graph, 'c')
assert(vim.fn.getreg('"') == main_commit, 'c must copy the full hash of the cursor row, not the focused commit')
press(st.wins.graph, 'f')
assert(st.focus == head and vim.api.nvim_win_get_cursor(st.wins.graph)[1] == st.index[head],
  'f must return the graph cursor to the focused commit without changing focus')
press(st.wins.graph, 'o')
local full_diff_win = vim.api.nvim_get_current_win()
local full_diff = table.concat(lines(vim.api.nvim_win_get_buf(full_diff_win)), '\n')
assert(full_diff:find('+extra', 1, true) and full_diff:find('+unrelated', 1, true),
  'commit details must show changes to both the viewed file and other files')
press(full_diff_win, ']c')
press(full_diff_win, ']c')
local second_hunk = vim.api.nvim_win_get_cursor(full_diff_win)[1]
local all_diff_lines = lines(vim.api.nvim_win_get_buf(full_diff_win))
local file_headers = {}
for i, line in ipairs(all_diff_lines) do
  if line:match('^diff %-%-git ') then file_headers[#file_headers + 1] = i end
end
assert(#file_headers == 2 and second_hunk > file_headers[2] and all_diff_lines[second_hunk]:match('^@@ '),
  'diff navigation must jump between files in the full commit')
press(full_diff_win, 'q')

-- ------------------------------------------------------------------ teardown
gb.focus_commit(head)
press(st.wins.graph, 'q')
assert(gb.state() == nil, 'the view state must be gone after q')
assert(#vim.api.nvim_list_wins() == 1, 'q must close the graph and meta panes')
assert(vim.api.nvim_get_current_win() == orig_win, 'q must return focus to the original window')
assert(vim.api.nvim_win_get_buf(orig_win) == orig_buf, 'q must show the user buffer again')
assert(vim.api.nvim_get_option_value('scrollbind', { win = orig_win }) == orig_scrollbind,
  'q must restore the original scrollbind setting')
assert(vim.api.nvim_get_option_value('signcolumn', { win = orig_win }) == orig_signcolumn,
  'q must restore the original signcolumn setting')
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
  assert(not vim.api.nvim_buf_get_name(buf):match('^gitblame://'), 'plugin buffers must be wiped')
end
assert(#markers(orig_buf) == 0, 'plugin markers must be gone on close')

-- reopening for an explicit path works and focuses HEAD again
gb.setup({ keymaps = { help = '?', parent = 'gp', child = '' } })
gb.open(repo .. '/' .. FILE)
local st2 = gb.state()
assert(st2 and st2.focus == head, 'opening an explicit path must work')
press(st2.wins.content, '?')
local popup = vim.api.nvim_get_current_win()
local shown = '\n' .. table.concat(lines(vim.api.nvim_win_get_buf(popup)), '\n')
assert(shown:find('\ngp  ', 1, true) and shown:find('\n?  ', 1, true), 'help must list remapped keys')
assert(not shown:find('\nP  ', 1, true), 'help must omit disabled mappings')
-- the popup belongs to the view: a second h replaces it, and the view closing closes it
vim.api.nvim_set_current_win(st2.wins.graph)
press(st2.wins.graph, '?')
assert(#vim.api.nvim_list_wins() == 4, 'a second h must replace the open popup, not stack another window')
assert(vim.api.nvim_get_current_win() ~= popup, 'the replacement popup is a fresh window')
gb.close()
assert(#vim.api.nvim_list_wins() == 1, 'closing the view must close its shortcut popup')
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
  assert(not vim.api.nvim_buf_get_name(buf):match('^gitblame://'), 'the popup buffer must go with the view')
end

-- Removed text renders at the diff positions without shifting real lines.
local remaining = { 'l2', 'l3', 'changed', 'feature', 'resolved' }
vim.fn.writefile(remaining, repo .. '/' .. FILE)
local wide_author = '田田田田田田田'
git('commit', '-am', 'delete and replace lines', '--author=' .. wide_author .. 'Extra <delete@example.com>',
  '--date=2024-02-03T12:00:00Z')
assert(gb.open(repo .. '/' .. FILE))
local removed_view = gb.state()
assert(focus_line(removed_view.bufs.graph):find('+1 -3', 1, true),
  'the graph must show both added and removed line counts')
local graph_buf = removed_view.bufs.graph
local graph_row = removed_view.index[removed_view.focus] - 1
local graph_text = lines(graph_buf)[graph_row + 1]
local colored = {}
for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(graph_buf, -1, { graph_row, 0 }, { graph_row, -1 }, { details = true })) do
  local details = mark[4]
  if details.hl_group and details.end_col then
    colored[details.hl_group] = graph_text:sub(mark[3] + 1, details.end_col)
  end
end
assert(colored.GitBlameAdded == '+1' and colored.GitBlameRemoved == '-3',
  'the addition and deletion columns must use their own highlights')
local function virtual_rows(buf)
  local rows = {}
  for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { details = true })) do
    local details = mark[4]
    for _, line in ipairs(details.virt_lines or {}) do
      local text = table.concat(vim.tbl_map(function(chunk) return chunk[1] end, line))
      rows[#rows + 1] = { mark[2], details.virt_lines_above or false, text }
    end
  end
  return rows
end
local cb, mb = removed_view.bufs.content, removed_view.bufs.meta
assert(vim.deep_equal(lines(cb), remaining), 'deleted lines must not enter the content buffer')
assert(vim.deep_equal(virtual_rows(cb), { { 0, true, 'l1' }, { 1, false, 'main' }, { 4, false, 'extra' } }),
  'deleted text must appear at the beginning, before the replacement, and at the end')
local removed_hl = vim.api.nvim_get_hl(0, { name = 'GitBlameRemovedLine' })
assert(removed_hl.bg == 0x652626, 'deleted rows must have a red background by default')
for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(cb, -1, 0, -1, { details = true })) do
  for _, row in ipairs(mark[4].virt_lines or {}) do
    assert(row[1][2] == 'GitBlameRemovedLine', 'deleted text must use the red background highlight')
  end
end
local deletion = '-  ' .. git('rev-parse', '--short=8', 'HEAD') .. ' ' .. wide_author .. ' 2024-02-03'
local width = vim.api.nvim_win_get_width(removed_view.wins.meta)
local normal_row = lines(mb)[3]
assert(normal_row:find(wide_author .. ' ', 1, true) and not normal_row:find('Extra', 1, true),
  'regular blame rows must truncate wide authors before the date')
assert(vim.fn.strdisplaywidth(deletion) == width and vim.fn.strdisplaywidth(normal_row) == width,
  'the full dates must fit and align in both kinds of rows')
assert(vim.deep_equal(virtual_rows(mb), { { 0, true, deletion }, { 1, false, deletion }, { 4, false, deletion } }),
  'each deleted row must show the deleting commit hash, author, and aligned date in the left pane')
vim.api.nvim_win_set_cursor(removed_view.wins.content, { 3, 0 })
press(removed_view.wins.content, ']c')
assert(vim.api.nvim_win_get_cursor(removed_view.wins.content)[1] == #remaining,
  'a deletion after EOF must be reachable on the last real line')
-- t only redraws: the file, blame and diffs must stay cached
local git_api = require('gitblame.git')
local saved_show = git_api.show_file
git_api.show_file = function() error('t must redraw from the cache, not read git again') end
press(removed_view.wins.content, 't')
assert(#virtual_rows(cb) == 0 and #virtual_rows(mb) == 0, 't must hide the deleted rows in both panes')
press(removed_view.wins.content, 't')
assert(#virtual_rows(cb) == 3 and #virtual_rows(mb) == 3, 't must bring the deleted rows back from the cache')
git_api.show_file = saved_show
gb.close()

-- An off-branch deletion has no graph row, but still has commit metadata.
git('switch', '-qc', 'off-graph')
vim.fn.writefile({ 'l2', 'changed', 'feature', 'resolved' }, repo .. '/' .. FILE)
git('commit', '-am', 'delete middle line', '--date=2024-02-05T12:00:00Z')
local off_graph = git('rev-parse', 'HEAD')
git('switch', '-q', 'main')
assert(gb.open(repo .. '/' .. FILE))
local off_view = gb.state()
assert(not off_view.index[off_graph] and gb.focus_commit(off_graph), 'an off-graph deletion must render')
local off_meta = virtual_rows(off_view.bufs.meta)
assert(#off_meta == 1 and off_meta[1][3] == '-  ' .. off_graph:sub(1, 8) .. ' Tester         2024-02-05',
  'an off-graph deletion must still show its author and date')
vim.api.nvim_win_set_cursor(off_view.wins.content, { 1, 0 })
press(off_view.wins.content, ']c')
assert(vim.api.nvim_win_get_cursor(off_view.wins.content)[1] == 2,
  'a pure deletion must navigate to the first real line after the deleted text')
gb.close()

-- Both views share a global scroll setting, even if closed out of order.
local saved_scrollopt = vim.o.scrollopt
vim.o.scrollopt = 'ver,hor,jump'
assert(gb.open(repo .. '/' .. FILE))
local first_tab = vim.api.nvim_get_current_tabpage()
vim.cmd.tabnew()
assert(gb.open(repo .. '/' .. FILE))
local second_tab = vim.api.nvim_get_current_tabpage()
assert(gb.close(first_tab) and vim.o.scrollopt == 'ver,jump', 'the remaining view must keep vertical-only scroll')
assert(gb.close(second_tab) and vim.o.scrollopt == 'ver,hor,jump', 'the last close must restore scrollopt')
vim.api.nvim_set_current_tabpage(second_tab)
vim.cmd.tabclose()
vim.o.scrollopt = saved_scrollopt

-- A rendering error after splits are created must unwind the view.
local git_module = require('gitblame.git')
local saved_show_file = git_module.show_file
git_module.show_file = function() error('test rendering failure') end
ok, err = gb.open(repo .. '/' .. FILE)
git_module.show_file = saved_show_file
assert(not ok and err:match('test rendering failure'), 'initial render failures must be returned')
assert(not gb.state() and #vim.api.nvim_list_wins() == 1 and vim.o.scrollopt == saved_scrollopt,
  'render failure must restore the layout and scroll settings')

local expanded = vim.list_extend(vim.deepcopy(remaining), vim.fn['repeat']({ 'new line' }, 1000))
vim.fn.writefile(expanded, repo .. '/' .. FILE)
git('commit', '-am', 'add four-digit count')
assert(gb.open(repo .. '/' .. FILE))
local wide_view = gb.state()
local wide_graph = lines(wide_view.bufs.graph)
local wide_row = wide_graph[wide_view.index[wide_view.focus]]
local narrow_row = wide_graph[wide_view.index[head]]
local _, wide_end = wide_row:find('+1000', 1, true)
local _, narrow_end = narrow_row:find('+1', 1, true)
assert(wide_end and narrow_end and vim.fn.strdisplaywidth(wide_row:sub(1, wide_end))
  == vim.fn.strdisplaywidth(narrow_row:sub(1, narrow_end)), 'one- and four-digit counts must align on screen')
assert(wide_row:find(' | +1000 -0 | ', 1, true) and narrow_row:find(' |    +1 -0 | ', 1, true),
  'the additions column must grow without widening the deletions column')
gb.close()

-- The commit diff uses Git hunk boundaries, with independently foldable blocks.
expanded[2], expanded[20] = 'first edit', 'second edit'
vim.fn.writefile(expanded, repo .. '/' .. FILE)
git('commit', '-am', 'two separate diff hunks')
assert(gb.open(repo .. '/' .. FILE))
assert(gb.open_commit())
local diff_win = vim.api.nvim_get_current_win()
local hunks = {}
for i, line in ipairs(lines(vim.api.nvim_get_current_buf())) do
  if line:match('^@@ ') then
    hunks[#hunks + 1] = i
  end
end
assert(#hunks == 2 and vim.fn.foldclosed(hunks[1]) == -1, 'diff hunks must start open')
press(diff_win, ']c')
assert(vim.api.nvim_win_get_cursor(diff_win)[1] == hunks[1], ']c must jump to the first hunk header')
vim.cmd('normal! zc')
assert(vim.fn.foldclosed(hunks[1] + 1) == hunks[1] and vim.fn.foldclosed(hunks[2]) == -1,
  'closing one hunk must not close the next')
press(diff_win, ']c')
assert(vim.api.nvim_win_get_cursor(diff_win)[1] == hunks[2], ']c must jump over a folded hunk')
vim.api.nvim_win_set_cursor(diff_win, { hunks[2] + 1, 0 })
press(diff_win, '[c')
assert(vim.api.nvim_win_get_cursor(diff_win)[1] == hunks[1], '[c must jump to the previous hunk from inside a block')
vim.cmd('normal! zo')
assert(vim.fn.foldclosed(hunks[1]) == -1, 'zo must reopen a diff hunk')
press(diff_win, 'q')
gb.close()

-- Adjacent changed lines are one stop for ]c / [c.
vim.fn.writefile({ 'a', 'b', 'c', 'd', 'e', 'f', 'g' }, repo .. '/' .. FILE)
git('commit', '-am', 'baseline for change blocks')
vim.fn.writefile({ 'a', 'B', 'C', 'd', 'e', 'F', 'g' }, repo .. '/' .. FILE)
git('commit', '-am', 'two adjacent changes and one later')
assert(gb.open(repo .. '/' .. FILE))
local block_view = gb.state()
assert(block_view.focus == git('rev-parse', 'HEAD'), 'the view must focus the commit just made')
vim.api.nvim_win_set_cursor(block_view.wins.content, { 1, 0 })
press(block_view.wins.content, ']c')
assert(vim.api.nvim_win_get_cursor(block_view.wins.content)[1] == 2, ']c must jump to the first changed line')
press(block_view.wins.content, ']c')
assert(vim.api.nvim_win_get_cursor(block_view.wins.content)[1] == 6,
  ']c from inside a two-line block must go to the next block, not to its second line')
press(block_view.wins.content, ']c')
assert(vim.api.nvim_win_get_cursor(block_view.wins.content)[1] == 6
    and last_notice():match('no next change'), ']c must not wrap past the last block')
press(block_view.wins.content, '[c')
assert(vim.api.nvim_win_get_cursor(block_view.wins.content)[1] == 2,
  '[c must step back to the start of the previous block')
press(block_view.wins.content, '[c')
assert(vim.api.nvim_win_get_cursor(block_view.wins.content)[1] == 2
    and last_notice():match('no previous change'), '[c must not wrap before the first block')
vim.api.nvim_win_set_cursor(block_view.wins.meta, { 2, 0 })
vim.api.nvim_win_set_cursor(block_view.wins.content, { 1, 0 })
press(block_view.wins.meta, ']c')
assert(vim.api.nvim_win_get_cursor(block_view.wins.meta)[1] == 6
  and vim.api.nvim_win_get_cursor(block_view.wins.content)[1] == 6,
  ']c in the left pane must start at its cursor and move both panes')
press(block_view.wins.meta, '[c')
assert(vim.api.nvim_win_get_cursor(block_view.wins.meta)[1] == 2
  and vim.api.nvim_win_get_cursor(block_view.wins.content)[1] == 2,
  '[c in the left pane must return both panes to the previous change block')
gb.close()
-- A commit where the file is gone, and one where it is empty.
git('switch', '-qc', 'gone')
vim.fn.delete(repo .. '/' .. FILE)
git('commit', '-qam', 'delete the file', '--date=2024-03-01T12:00:00Z')
local gone_commit = git('rev-parse', 'HEAD')
vim.fn.writefile({ '-back' }, repo .. '/' .. FILE)
git('add', FILE)
git('commit', '-qm', 'bring it back', '--date=2024-03-02T12:00:00Z')
vim.fn.writefile({}, repo .. '/' .. FILE)
git('commit', '-qam', 'empty the file', '--date=2024-03-03T12:00:00Z')
assert(gb.open(repo .. '/' .. FILE))
local gone_view = gb.state()
assert(gb.focus_commit(gone_commit), 'a commit without the file must not throw')
assert(lines(gone_view.bufs.content)[1]
    == 'file did not exist at ' .. gone_commit:sub(1, 8) .. ' (' .. FILE .. ')',
  'the content pane must say why it shows nothing')
assert(#lines(gone_view.bufs.meta) == 1, 'the left pane collapses to one row when the file is gone')
-- an emptied file still deleted lines, so ]c must not claim the commit changed nothing
local empty_commit = git('log', '--format=%H', '-1', '--grep', 'empty the file', '--', FILE)
assert(gb.focus_commit(empty_commit), 'the commit that emptied the file must not throw')
assert(gone_view.line_count == 0, 'an emptied file has no lines')
assert(vim.deep_equal(virtual_rows(gone_view.bufs.content), { { 0, true, '-back' } }),
  'only the diff prefix is removed; a dash in the original text must stay')
press(gone_view.wins.content, ']c')
assert(not last_notice():match('changed no lines'),
  'a commit that deleted every line must not report that it changed nothing: ' .. last_notice())
local nil_ok, nil_err = gb.focus_commit(nil)
assert(not nil_ok and tostring(nil_err):match('no commit given'), 'focus_commit(nil) must refuse, not throw')
gb.close()

-- the left pane keeps its width: 8 hash digits, and the author shrinks to fit
vim.fn.writefile({ 'one', 'two', 'three' }, repo .. '/' .. FILE)
git('commit', '-am', 'content again')
gb.setup({ hash_length = 12 })
assert(gb.open(repo .. '/' .. FILE))
local wide_hash = gb.state()
local pane_width = vim.api.nvim_win_get_width(wide_hash.wins.meta)
local blame_row = lines(wide_hash.bufs.meta)[1]
assert(pane_width == 37, 'the left pane keeps meta_width whatever hash_length says')
assert(blame_row:sub(4, 11):match('^%x%x%x%x%x%x%x%x$'), 'the left pane always shows 8 hash digits: ' .. blame_row)
assert(vim.fn.strdisplaywidth(blame_row) == pane_width, 'a blame row fills its pane exactly: ' .. blame_row)
gb.close()
gb.setup({})
-- the top pane takes the history, the ratio caps it, and three rows are the floor
gb.setup({ top_ratio = 0.9 })
assert(gb.open(repo .. '/' .. FILE))
local tall_view = gb.state()
local listed_rows = #tall_view.rows
assert(vim.api.nvim_win_get_height(tall_view.wins.graph) == listed_rows,
  'a ratio bigger than the history must not leave empty rows above the graph')
press(tall_view.wins.graph, 'F')
assert(vim.api.nvim_win_get_height(tall_view.wins.graph) == #tall_view.rows,
  'toggling --follow must fit the graph pane to the resulting layout')
local followed_rows = #tall_view.rows
vim.fn.writefile({ 'one more line' }, repo .. '/' .. FILE, 'a')
git('commit', '-am', 'extend the graph')
assert(gb.refresh() and #tall_view.rows == followed_rows + 1
    and vim.api.nvim_win_get_height(tall_view.wins.graph) == #tall_view.rows,
  'refresh must grow the graph pane when the layout gains a row')
gb.close()
gb.setup({ top_ratio = 0.02 })
assert(gb.open(repo .. '/' .. FILE))
assert(vim.api.nvim_win_get_height(gb.state().wins.graph) == 3, 'the graph pane keeps at least three rows')
gb.close()
gb.setup({})

-- A link from b to d crosses the independent lane to c without joining it.
local crossing = require('gitblame.graph').parse(table.concat({
  '\31a\31b c d', '\31b\31d', '\31c\31', '\31d\31',
}, '\n'))
local crossing_row = crossing.rows[4]
assert(crossing_row.child == 'b' and crossing_row.art == '└─│─┤',
  'a crossing must draw only the vertical stroke, without changing real junctions')
local vertical = crossing_row.segments[3]
assert(vertical.target == 'c' and not vertical.branch,
  'highlighting the horizontal link must not highlight the unrelated lane')

os.remove(outside)
vim.system({ '/bin/sh', '-c', 'rm -rf "$1"', 'sh', sandbox }):wait()

print('gitblame: all assertions passed')
