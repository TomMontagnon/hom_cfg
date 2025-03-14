#! /bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")"
print

dir="layouts.d"

selected=$(fd . $dir -d 1 --exec basename {} \; | fzf)

echo $dir/$selected

zellij --layout $dir/$selected
