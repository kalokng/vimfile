#!/usr/bin/env bash
mkdir -p ~/.config/
cd "$(dirname "$0")"
ln -s "$(dirname "$0")"/nvim ~/.config/nvim
