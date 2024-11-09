#!/bin/bash

# Enter its not a worktree or a base repo and exits
if ! git rev-parse --is-inside-work-tree > /dev/null; then
	exit 1
fi

DOT_GIT_MAIN_FOLDER=$(realpath $(git rev-parse --git-common-dir 2>/dev/null))
OLD_BRANCH_FILE="$DOT_GIT_MAIN_FOLDER/gsw-old-branch.txt"

# Keep the current origin branch in memory
current_branch=$(git rev-parse --abbrev-ref HEAD)

select='False'
if [[ $# -eq 0 ]]; then
	select='True'
fi

# Selected branch
target_branch=""
if [ "$select" = 'True' ]; then
	selection=$(git for-each-ref --format='%(refname:short)' refs/heads/ 2>/dev/null) # Git branches
	selection="$selection"$'\n'"-" # -
	selection="$selection"$'\n'"--" # --
	target_branch=$(echo "$selection" | fzf)
else
	target_branch="$1"
fi

# Special cases (git switch -)
if [ "$target_branch" = "-" ]; then
	target_branch=$(cat "$OLD_BRANCH_FILE" 2>/dev/null)
elif [ "$target_branch" = "--" ]; then # Use the regular last branch (worktree specific)
	target_branch=$(git rev-parse --abbrev-ref @{-1})
fi

# Sanitization
if [ -z "$target_branch" ]; then
	echo "No branch were given." >&2
	exit 1
fi

if git show-ref --verify --quiet "refs/heads/$target_branch"; then
	echo "The branch $target_branch doesnt exist." >&2
	exit 1
fi

if [ "$target_branch" == "$current_branch" ]; then
	exit 0 # Nothing to do
fi

# Get the folder
dir=$(git worktree list | awk -v branch="[$target_branch]" '$3==branch {print $1; exit 0}')

if [ -n "$dir" ]; then
	echo "Switching to worktree $target_branch" >&2
	cd "$dir" || exit 1
else
	git switch "$target_branch" || exit 1
fi

# Update OLD_BRANCH_FILE
echo "$current_branch" > "$OLD_BRANCH_FILE"
