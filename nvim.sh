#!/usr/bin/env bash
set -e
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
mkdir -p "$CONFIG_DIR"
# cd+pwd instead of readlink -f: works on old macOS and when called via a relative path
SRC="$(cd "$(dirname "$0")" && pwd)/nvim"
DEST="$CONFIG_DIR/nvim"
# ln -sfn into an existing real directory would silently nest the link inside it
if [ -e "$DEST" ] && [ ! -L "$DEST" ]; then
    echo "$DEST exists and is not a symlink - move it away first" >&2
    exit 1
fi
ln -sfn "$SRC" "$DEST"
