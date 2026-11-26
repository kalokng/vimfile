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
| top (up to 1/3 height) | `[focus][graph][short hash][date][+added -removed][author][subject]`, one row per commit of the file, merges and branch lanes included; the pane is only as tall as the history needs |
| left | per-line change marker, 8-digit blame hash, author, date — the pane is `meta_width` wide, so the author is shortened to keep the date visible; deleted lines show the hash, author, and date of the commit that deleted them |
| content | the file as of the focused commit, with `+` / `~` markers and inline red-highlighted lines showing what the commit deleted |

Counts apply to the selected file, not the whole commit. Each count column fits its widest value. Merge counts are relative to the first parent. The author column is clipped and padded to `author_width`, so subjects start in one column.
Move the cursor in the top pane to highlight the selected commit and its connections to visible parents.

## Keys

Defaults; every one is configurable through `setup{ keymaps = { ... } }`.

| key | panes | action |
| --- | --- | --- |
| `<CR>` | graph | focus the commit under the cursor |
| `f` | graph | return the cursor to the focused commit without changing focus |
| `c` | graph | copy the full hash under the cursor to the clipboard, or yank it if no clipboard is available |
| `<CR>` | left, content | focus the commit that changed that line |
| `p` | all three | focus the parent commit |
| `P` | all three | focus the child commit |
| `t` | all three | show / hide change markers and deleted lines |
| `F` | all three | toggle `--follow` (rename tracking) and re-read the history |
| `o` | all three | open the full commit (header, message, diff for all changed files) in a new tab: the row under the cursor in the graph, the line under the cursor in the meta pane, the focused commit in the content pane |
| `]c` | left, content | jump to the next change block of the focus commit (added lines, uncommitted lines, or removal points); adjacent changed lines count as one block, so a two-line addition is one stop; no wrapping |
| `[c` | left, content | jump to the start of the previous change block; no wrapping |
| `h` | all three | show the shortcut popup; dismiss it with `<Esc>` or `q` |
| `Ctrl-O` / `Ctrl-I` | left, content | go back / forward through focused commits |
| `q` | all three (and the commit tab) | close the view and restore the previous layout |

In the commit details opened with `o`, `]c` / `[c` jump between diff hunks.
Hunks start open; use `zc` to fold one, `zo` to reopen it, or `za` to toggle it.

`p` at a root commit and `P` at the newest commit do nothing but tell you why. When the
parent exists in the repository but outside the simplified file history, the view says so
instead of jumping.

## Options

```lua
require('gitblame').setup({
  follow = false,          -- start with --follow on
  show_changes = true,     -- start with change markers visible
  top_ratio = 0.34,        -- maximum top pane height as a fraction of the screen
  meta_width = 37,         -- left pane width; fixed, the author column shrinks to fit
  focus_sign = '>',        -- marker in the left-most column of the focused row
  hash_length = 8,         -- hash characters in the graph pane; the left pane always shows 8
  author_width = 14,       -- author column width in the graph pane
  keymaps = {
    parent = 'p', child = 'P', toggle_changes = 't', toggle_follow = 'F',
    close = 'q', select = '<CR>', open_commit = 'o',
    jump_to_focus = 'f', copy_hash = 'c',
    focus_back = '<C-o>', focus_forward = '<C-i>',
    help = 'h',
    next_change = ']c', prev_change = '[c',
  },
})
```

Highlights to override if the defaults do not fit your colorscheme:
`GitBlameFocus`, `GitBlameIndicator`, `GitBlameGraph`, `GitBlameGraphSelected`, `GitBlameHash`, `GitBlameAuthor`,
`GitBlameDate`, `GitBlameAdded`, `GitBlameAddedLine`, `GitBlameRemoved`, `GitBlameRemovedLine`,
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
- Removed lines are shown inline as display-only rows with a red background. They do not change the
  committed file's line numbers. The left pane identifies the deleting commit.
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
