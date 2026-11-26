-- Synchronous git CLI helpers. Zero dependencies: everything goes through vim.system.
local M = {}

local BASE = { 'git', '--no-pager', '-c', 'color.ui=false', '-c', 'core.quotepath=false' }

--- Run git in `cwd` and return stdout, or nil plus an error message.
---@param args string[]
---@param cwd string?
---@return string? out, string? err
function M.run(args, cwd)
  local cmd = {}
  for _, a in ipairs(BASE) do
    cmd[#cmd + 1] = a
  end
  for _, a in ipairs(args) do
    cmd[#cmd + 1] = a
  end
  local ok, obj = pcall(vim.system, cmd, { text = true, cwd = cwd })
  if not ok then
    return nil, tostring(obj)
  end
  local res = obj:wait()
  if res.code ~= 0 then
    local err = vim.trim(res.stderr or '')
    if err == '' then
      err = vim.trim(res.stdout or '')
    end
    if err == '' then
      err = 'git ' .. table.concat(args, ' ') .. ' exited ' .. tostring(res.code)
    end
    return nil, err
  end
  return res.stdout or ''
end

--- Split git output into lines, dropping only the empty piece after the final newline.
---@param s string?
---@return string[]
function M.lines(s)
  if not s or s == '' then
    return {}
  end
  local out = vim.split(s, '\n', { plain = true })
  if #out > 0 and out[#out] == '' then
    table.remove(out)
  end
  return out
end

--- Repository top-level directory containing `file`, or nil.
function M.root_for(file)
  local dir = vim.fn.fnamemodify(file, ':p:h')
  local out = M.run({ 'rev-parse', '--show-toplevel' }, dir)
  if not out then
    return nil
  end
  return vim.trim(out)
end

--- Repo-relative path of `file` when it is tracked, else nil.
--- `--full-name` keeps the path relative to the top level even though we run with -C dir.
function M.tracked_path(file)
  local dir = vim.fn.fnamemodify(file, ':p:h')
  local base = vim.fn.fnamemodify(file, ':t')
  local out = M.run({ 'ls-files', '--full-name', '--error-unmatch', '--', base }, dir)
  if not out then
    return nil
  end
  local rel = vim.trim(out)
  return rel ~= '' and rel or nil
end

---@return string[] parent hashes of rev
function M.parents(root, rev)
  local out = M.run({ 'rev-list', '--parents', '-n', '1', rev }, root)
  if not out then
    return {}
  end
  local parts = vim.split(vim.trim(out), ' ', { plain = true })
  table.remove(parts, 1) -- the commit itself
  return parts
end

--- Last commit touching `rel`, i.e. the commit HEAD's version of the file points at.
function M.head_file_commit(root, rel, follow)
  local args = { 'log', '-1', '--format=%H' }
  if follow then
    args[#args + 1] = '--follow'
  end
  args[#args + 1] = '--'
  args[#args + 1] = rel
  local out = M.run(args, root)
  if not out then
    return nil
  end
  local sha = vim.trim(out)
  return sha ~= '' and sha or nil
end

--- `git log --graph` with a machine readable, single-line entry per commit.
--- tformat: guarantees a trailing newline after the last entry.
function M.log_graph(root, rel, follow)
  -- the leading %x1f keeps the graph art cleanly separated from the fields
  local args = { 'log', '--graph', '--date=short', '--pretty=tformat:%x1f%H%x1f%P%x1f%an%x1f%ad%x1f%s' }
  if follow then
    args[#args + 1] = '--follow'
  end
  args[#args + 1] = '--'
  args[#args + 1] = rel
  return M.run(args, root)
end

--- Map commit -> the path that commit touched, so content/blame work across renames.
function M.paths_at(root, rel, follow)
  local args = { 'log', '--format=%H', '--name-only' }
  if follow then
    args[#args + 1] = '--follow'
  end
  args[#args + 1] = '--'
  args[#args + 1] = rel
  local out = M.run(args, root)
  local map = {}
  if not out then
    return map
  end
  local cur
  for _, line in ipairs(M.lines(out)) do
    if #line == 40 and line:match('^%x+$') then
      cur = line
    elseif line ~= '' and cur and line ~= '\\ No newline at end of file' and not map[cur] then
      map[cur] = line
    end
  end
  return map
end

--- File content at `rev:path`, or nil + error.
function M.show_file(root, rev, path)
  return M.run({ 'show', '--no-color', rev .. ':' .. path }, root)
end

local function hunk(line)
  -- "@@ -a[,ac] +b[,bc] @@"; a count of 1 is omitted by git.
  local o_start, o_count, n_start, n_count =
    line:match('^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@')
  if not o_start then
    return nil
  end
  return tonumber(o_start), (o_count ~= '' and tonumber(o_count) or 1),
    tonumber(n_start), (n_count ~= '' and tonumber(n_count) or 1)
end

--- Lines the commit added (new-file line numbers) and removed (count keyed by the new-file
--- line the removal happened at), relative to its first parent.
--- `removed_text` is keyed by the new-file line before which the deleted text belongs.
---@return { added: table<integer,boolean>, removed: table<integer,integer>, removed_text: table<integer,string[]> }
function M.changed_lines(root, rev, path)
  local added, removed, removed_text = {}, {}, {}
  local parents = M.parents(root, rev)
  local out
  if parents[1] then
    out = M.run({ 'diff', '--no-color', '--unified=0', parents[1], rev, '--', path }, root)
  else
    out = M.run({ 'show', '--no-color', '--format=', '--unified=0', rev, '--', path }, root)
  end
  if not out then
    return { added = added, removed = removed, removed_text = removed_text }
  end
  local deleted, remaining
  for _, line in ipairs(M.lines(out)) do
    local o_start, o_count, n_start, n_count = hunk(line)
    if o_start then
      deleted, remaining = nil, o_count
      for i = n_start, n_start + n_count - 1 do
        added[i] = true
      end
      if o_count > 0 then
        -- With no new lines, Git reports the line *before* the deletion.
        local before = n_start + (n_count == 0 and 1 or 0)
        removed[before] = (removed[before] or 0) + o_count
        deleted = removed_text[before] or {}
        removed_text[before] = deleted
      end
    elseif deleted and remaining > 0 and line:sub(1, 1) == '-' then
      deleted[#deleted + 1] = line
      remaining = remaining - 1
    end
  end
  return { added = added, removed = removed, removed_text = removed_text }
end

--- Line numbers of the `rev` version that differ in the working tree (uncommitted edits).
---@return table<integer, boolean>
function M.worktree_touched(root, rev, path)
  local touched = {}
  local out = M.run({ 'diff', '--no-color', '--unified=0', rev, '--', path }, root)
  if not out then
    return touched
  end
  for _, line in ipairs(M.lines(out)) do
    local o_start, o_count = hunk(line)
    if o_start and o_count > 0 then
      for i = o_start, o_start + o_count - 1 do
        touched[i] = true
      end
    end
  end
  return touched
end

--- Per-line blame metadata for `path` at `rev` (rev nil = working tree).
---@return { sha: string, author: string, date: string, boundary: boolean }[]? entries
function M.blame(root, rev, path)
  local args = { 'blame', '--line-porcelain' }
  if rev then
    args[#args + 1] = rev
  end
  args[#args + 1] = '--'
  args[#args + 1] = path
  local out, err = M.run(args, root)
  if not out then
    return nil, err
  end
  local entries = {}
  for _, line in ipairs(M.lines(out)) do
    local sha = line:match('^(%x+) %d+ %d+')
    if sha then
      entries[#entries + 1] = { sha = sha, author = '', date = '', boundary = false }
    elseif #entries > 0 then
      local entry = entries[#entries]
      local key, value = line:match('^(%S+) (.*)$')
      if key == 'author' then
        entry.author = value
      elseif key == 'author-time' then
        entry.date = os.date('%Y-%m-%d', tonumber(value) or 0) or ''
      elseif key == 'boundary' then
        entry.boundary = true
      end
    end
  end
  return entries
end

function M.commit_author_date(root, rev)
  local out = M.run({ 'show', '-s', '--date=short', '--format=%ad%n%an', '--end-of-options', rev, '--' }, root)
  local date, author = unpack(M.lines(out))
  return { date = date or '', author = author or '' }
end

--- Commit header + message (author, committer, date, subject, body).
function M.commit_text(root, rev)
  return M.run({ 'show', '--no-patch', '--format=fuller', rev }, root)
end

--- Full diff of `rev` for `path`, against the first parent (or the empty tree for a root commit).
function M.commit_diff(root, rev, path)
  local parents = M.parents(root, rev)
  if parents[1] then
    return M.run({ 'diff', '--no-color', parents[1], rev, '--', path }, root)
  end
  return M.run({ 'show', '--no-color', '--format=', rev, '--', path }, root)
end

return M
