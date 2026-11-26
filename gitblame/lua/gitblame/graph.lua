-- Parses `git log --graph` output into rows the view can render.
-- Each output line is either a commit entry ("<graph art>\x1f<fields>") or a pure
-- graph/edge line ("|\", "|/", "...") that belongs to no commit.
local git = require('gitblame.git')

local M = {}

local SEP = '\31' -- unit separator, cannot appear in a commit subject in practice

--- Parse raw `git log --graph` output.
---@return { art_width: integer, rows: table[] }
function M.parse(raw)
  local rows = {}
  local width = 1
  for _, line in ipairs(git.lines(raw)) do
    local sep = line:find(SEP, 1, true)
    if sep then
      local head = line:sub(1, sep - 1)
      local fields = vim.split(line:sub(sep + 1), SEP, { plain = true })
      local art, sha = head, fields[1]
      if not (sha and #sha == 40) then
        -- fallback for formats where the hash sits right after the graph art
        local split_art, split_sha = head:match('^(.-)(%x40)$')
        if split_art then
          art, sha = split_art, split_sha
        end
      end
      local parents = {}
      for parent in (fields[2] or ''):gmatch('%x+') do
        parents[#parents + 1] = parent
      end
      rows[#rows + 1] = {
        kind = 'commit',
        art = art,
        sha = sha,
        parents = parents,
        author = fields[3] or '',
        date = fields[4] or '',
        subject = fields[5] or '',
      }
    else
      rows[#rows + 1] = { kind = 'edge', art = line, sha = nil, parents = {} }
    end
    local row = rows[#rows]
    -- git does not pad the graph column, so normalise the art width for aligned columns
    row.art = (row.art:gsub('%s+$', '')) .. ' '
    if #row.art > width then
      width = #row.art
    end
  end
  return { rows = rows, art_width = width }
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
