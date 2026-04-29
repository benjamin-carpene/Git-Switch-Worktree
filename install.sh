#!/bin/env bash

set -e

GSW_REPO="https://github.com/benjamin-carpene/Git-Switch-Worktree.git"
GSW_DIR="$HOME/.local/gsw.app"

if [ -z "$HOME" ]; then
    echo "User has no HOME folder"
    exit 1
fi

if ! command -v git &>/dev/null; then
    echo "git is required but not installed"
    exit 1
fi

if [ -d "$GSW_DIR" ]; then
    echo "Updating existing installation..."
    git -C "$GSW_DIR" pull --ff-only
else
    echo "Cloning gsw..."
    git clone "$GSW_REPO" "$GSW_DIR"
fi

cd "$GSW_DIR"
bash install-local.sh
