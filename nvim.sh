#!/usr/bin/env bash
mkdir -p ~/.config/
ln -s "$(readlink -f $(dirname "$0"))/nvim" ~/.config/nvim
