-- Parse Git's commit order and draw the visible parent links in compact lanes.
local git = require('gitblame.git')
local M = {}

local SEP = '\31'
-- Direction bits: up, down, left, right. Prefer box drawing, with one-cell ASCII fallbacks.
local shapes = { '│', '│', '│', '─', '┘', '┐', '┤', '─', '└', '┌', '├', '─', '┴', '┬', '│' }
local fallback = { '|', '|', '|', '-', '+', '+', '+', '-', '+', '+', '+', '-', '+', '+', '|' }

local function layout(commits, visible)
  local rows, lanes, width = {}, {}, 1
  local glyphs = {}
  for mask, glyph in ipairs(shapes) do
    glyphs[mask] = vim.fn.strdisplaywidth(glyph) == 1 and glyph or fallback[mask]
  end
  local dot = vim.fn.strdisplaywidth('●') == 1 and '●' or '*'

  local function emit(row, cells, last)
    local art, offset = {}, 0
    row.segments = {}
    for col = 1, last do
      local cell = cells[col]
      local glyph = cell and (cell.node and dot or glyphs[cell.mask]) or ' '
      art[col] = glyph
      if cell then
        cell.start_col, cell.end_col = offset, offset + #glyph
        row.segments[#row.segments + 1] = cell
      end
      offset = offset + #glyph
    end
    row.art, row.cells = table.concat(art), last
    rows[#rows + 1] = row
    width = math.max(width, last)
  end

  local function lane_for(sha)
    local free
    for i, target in ipairs(lanes) do
      if target == sha then return i end
      if not target and not free then free = i end
    end
    return free or #lanes + 1
  end

  for _, commit in ipairs(commits) do
    visible[commit.sha] = nil
    local lane = lane_for(commit.sha)
    local cells = {}
    for i, target in ipairs(lanes) do
      if target then cells[2 * i - 1] = { mask = 3, target = target } end
    end
    local origin = 2 * lane - 1
    cells[origin] = { node = true, target = commit.sha }
    emit(commit, cells, math.max(origin, 2 * #lanes - 1))

    lanes[lane] = false
    local branches, fresh = {}, { [lane] = true }
    for _, parent in ipairs(commit.parents) do
      if visible[parent] then
        -- Keep the first new parent in the commit's lane; reuse an active lane if it already exists.
        local to = lane_for(parent)
        if lanes[to] ~= parent and not lanes[lane] then to = lane end
        if not lanes[to] then fresh[to] = true end
        lanes[to] = parent
        if to ~= lane then branches[#branches + 1] = 2 * to - 1 end
      end
    end
    if #branches > 0 then
      cells = {}
      for i, target in ipairs(lanes) do
        if target then cells[2 * i - 1] = { mask = fresh[i] and 2 or 3, target = target } end
      end
      local function connect(col, mask)
        local cell = cells[col] or { mask = 0 }
        cell.mask, cell.branch = bit.bor(cell.mask, mask), true
        cells[col] = cell
      end
      for _, target in ipairs(branches) do
        local left, right = math.min(origin, target), math.max(origin, target)
        -- An unrelated vertical lane stays visible where a horizontal link crosses it.
        for col = left + 1, right - 1 do
          if not cells[col] then connect(col, 12) end
        end
        connect(origin, target < origin and 5 or 9)
        connect(target, target < origin and 10 or 6)
      end
      emit({ kind = 'edge', child = commit.sha }, cells, math.max(origin, 2 * #lanes - 1))
    end
    while lanes[#lanes] == false do lanes[#lanes] = nil end
  end
  return { rows = rows, art_width = width }
end

function M.parse(raw)
  local commits, visible = {}, {}
  for _, line in ipairs(git.lines(raw)) do
    local sep = line:find(SEP, 1, true)
    if sep then
      local fields = vim.split(line:sub(sep + 1), SEP, { plain = true })
      local parents = {}
      for parent in (fields[2] or ''):gmatch('%x+') do
        parents[#parents + 1] = parent
      end
      commits[#commits + 1] = {
        kind = 'commit', sha = fields[1], parents = parents,
        author = fields[3] or '', date = fields[4] or '', subject = fields[5] or '',
      }
      visible[fields[1]] = true
    end
  end
  return layout(commits, visible)
end

--- sha -> row index, for commit rows only.
function M.index(rows)
  local index = {}
  for i, row in ipairs(rows) do
    if row.kind == 'commit' then
      index[row.sha] = i
    end
  end
  return index
end

--- sha -> list of child shas, derived from the parsed rows.
function M.children(rows)
  local children = {}
  for _, row in ipairs(rows) do
    if row.kind == 'commit' then
      for _, parent in ipairs(row.parents) do
        children[parent] = children[parent] or {}
        table.insert(children[parent], row.sha)
      end
    end
  end
  return children
end

return M
