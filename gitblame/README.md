# gitblame.nvim

A zero-dependency git blame browser for Neovim: a commit graph on top, the file below,
and the blame metadata of every line on the left. Pure Lua + the `git` CLI (`vim.system`),
no plenary, no libgit2.

```
>  *   9f2c1ab4 merge feature resolved
   |\
   | * dfd16aa2 feature: add line
 * | cedb84d06 main: add line
 |/
 * 676a1abf rename tracked to renamed
+--------+--------------------------------------------------+
|  676a1 | l1                                               |
|  676a1 | l2                                               |
|  cedb8 | main                                             |
|+ 9dc2a | extra                                            |
+--------+--------------------------------------------------+
```

## Install

With lazy.nvim and this repo as your config (already wired in
`nvim/lua/plugins/gitblame.lua`):

```lua
{ dir = '~/dev/vimfile/gitblame', name = 'gitblame', keys = { { '<leader>gb', '<cmd>GitBlame<cr>' } } }
```

Anywhere else, put `gitblame/` on your `runtimepath` and call `require('gitblame').setup{}`.

## Use

```
:GitBlame            " blame the current buffer's file
:GitBlame src/app.c  " blame another tracked file
```

The view opens with the cursor in the content pane at its first line; the graph pane
cursor sits on the focused commit row, so `j`/`k` there walks the history.

Three panes:

| pane | contents |
| --- | --- |
| top (~1/3 height) | `[focus][graph][short hash][subject]`, one row per commit of the file, merges and branch lanes included |
| left | per-line change marker, blame hash, author, date — line-for-line aligned with the content pane and scroll-locked to it |
| content | the file as of the focused commit, with `+` / `~` markers in the sign column |

## Keys

Defaults; every one is configurable through `setup{ keymaps = { ... } }`.

| key | panes | action |
| --- | --- | --- |
| `<CR>` | graph | focus the commit under the cursor |
| `<CR>` | meta | focus the commit that changed that line |
| `p` | all three | focus the parent commit |
| `P` | all three | focus the child commit |
| `t` | all three | show / hide the focus commit's `+`/`-` change markers |
| `F` | all three | toggle `--follow` (rename tracking) and re-read the history |
| `o` | all three | open the full commit (header, message, file diff) in a new tab: the row under the cursor in the graph, the line under the cursor in the meta pane, the focused commit in the content pane |
| `]c` | content | jump to the next change of the focus commit (added line, uncommitted line, or removal point); no wrapping |
| `[c` | content | jump to the previous change of the focus commit; no wrapping |
| `q` | all three (and the commit tab) | close the view and restore the previous layout |

`p` at a root commit and `P` at the newest commit do nothing but tell you why. When the
parent exists in the repository but outside the simplified file history, the view says so
instead of jumping.

## Options

```lua
require('gitblame').setup({
  follow = false,          -- start with --follow on
  show_changes = true,     -- start with change markers visible
  top_ratio = 0.34,        -- top pane height as a fraction of the screen
  meta_width = 36,         -- left pane width
  focus_sign = '>',        -- marker in the left-most column of the focused row
  hash_length = 8,         -- characters of the hash shown
  author_width = 14,       -- author column width in the meta pane
  keymaps = {
    parent = 'p', child = 'P', toggle_changes = 't', toggle_follow = 'F',
    close = 'q', select = '<CR>', open_commit = 'o',
    next_change = ']c', prev_change = '[c',
  },
})
```

Highlights to override if the defaults do not fit your colorscheme:
`GitBlameFocus`, `GitBlameIndicator`, `GitBlameGraph`, `GitBlameHash`, `GitBlameAuthor`,
`GitBlameDate`, `GitBlameAdded`, `GitBlameAddedLine`, `GitBlameRemoved`,
`GitBlameModified`, `GitBlameModifiedLine`.

## API

```lua
local gb = require('gitblame')
gb.open(path)          -- path nil = current buffer; returns true, state  or  nil, err
gb.close()             -- restore the previous layout
gb.refresh()           -- re-read history (useful after committing elsewhere)
gb.focus_parent() gb.focus_child() gb.focus_commit(sha)
gb.select() gb.focus_line_commit()
gb.toggle_changes() gb.toggle_follow()
gb.open_commit(sha)    -- commit header + diff in a new tab
gb.next_change() gb.prev_change()  -- same as ]c / [c
gb.state()             -- the live view state (used by the tests)
```

## Notes and limits

- The content pane shows the **committed** version of the file, never your live buffer.
  Lines that differ from the focused commit in your working tree are marked `~`.
- Removed lines cannot be shown in the content pane (they are gone from that revision);
  the meta pane marks the position with `-<count>`.
- Only the history of one path is listed. `git log -- <path>` simplifies history, so a
  merge that did not change the file does not appear; `--follow` trades some merge rows
  for commits from before a rename.
- Nothing writes to the repository: the plugin only runs read-only git commands.

## Test

```bash
nvim --headless -u NONE -l nvim/tests/gitblame.lua
```

It builds a throwaway repo (root commit, rename, branch, conflicting merge, head commit)
and asserts layout, row-to-commit mapping, focus rules, `p`/`P`/`t`/`F`/`q` in every pane,
blame columns, marker toggles and teardown.
