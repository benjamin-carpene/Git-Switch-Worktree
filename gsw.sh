function gsw() {
    # Enter its not a worktree or a base repo and exits
    if ! git rev-parse --is-inside-work-tree > /dev/null; then
        return 1
    fi

    DOT_GIT_MAIN_FOLDER=$(realpath $(git rev-parse --git-common-dir 2>/dev/null))
    OLD_BRANCH_FILE="$DOT_GIT_MAIN_FOLDER/gsw-old-branch.txt"

    # Keep the current origin branch in memory
    current_branch=$(git rev-parse --abbrev-ref HEAD)

    select_mode='False'
    if [[ $# -eq 0 ]]; then
        select_mode='True'
    fi

    # Selected branch
    target_branch=""
    if [ "$select_mode" = 'True' ]; then
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
        target_branch=$(git rev-parse --abbrev-ref @{-1} 2>/dev/null) || target_branch=''
    fi

    # Sanitization
    if [ -z "$target_branch" ]; then
        echo "No branch were given." >&2
        return 1
    fi

    if ! git show-ref --verify --quiet "refs/heads/$target_branch"; then
        echo "The branch $target_branch doesnt exist." >&2
        return 1
    fi

    if [ "$target_branch" = "$current_branch" ]; then
        return 0 # Nothing to do
    fi

    # Get the folder
    dir=$(git worktree list | awk -v branch="[$target_branch]" '$3==branch {print $1; exit 0}')

    if [ -n "$dir" ]; then
        echo "Switching to worktree $target_branch" >&2
        cd "$dir" || return 1
    else
        local root_dir
        root_dir=$(dirname "$DOT_GIT_MAIN_FOLDER")
        local worktree_path="$root_dir/$target_branch"
        echo "Creating worktree for $target_branch" >&2
        git worktree add "$worktree_path" "$target_branch" || return 1
        cd "$worktree_path" || return 1
    fi

    # Update OLD_BRANCH_FILE
    echo "$current_branch" > "$OLD_BRANCH_FILE"
}

# Clone for a bare repo with arguments URI (and name on disk if user wants a specific one)
gcw() {
  local url=$1
  local name=${2:-$(basename "$url" .git)}
  if [ -z "$url" ]; then
    echo 'Need at least one argument (url)'
    return 1
  fi
  if [ -z "$name" ]; then
    echo 'No name could be calculated from URL nor was given'
    return 2
  fi

  # Log for user
  echo "Cloning $url in $name"

  mkdir "$name" && cd "$name" || return 3

  # Clone and do the plumbing
  git clone --bare "$url" .bare
  echo "gitdir: ./.bare" > .git
  git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
  git fetch origin

  return 0
}

# For people who already had an alias :)
alias gsw=gsw
alias gcw=gcw
