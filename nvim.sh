#!/usr/bin/env bash
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
if [ -n "$XDG_CONFIG_HOME" ]; then
    CONFIG_DIR="$XDG_CONFIG_HOME"
else
    CONFIG_DIR=~
    mkdir -p ~/.config/
fi
ln -s "$(readlink -f $(dirname "$0"))/nvim" "$CONFIG_DIR/nvim"
