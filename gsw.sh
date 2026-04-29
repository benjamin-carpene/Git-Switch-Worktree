_gsw_switch() {
    local target_branch="$1"
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD)

    if [ "$target_branch" = "$current_branch" ]; then
        return 0
    fi

    local dir
    dir=$(git worktree list | awk -v branch="[$target_branch]" '$3==branch {print $1; exit 0}')

    if [ -n "$dir" ]; then
        # Worktree already exist : cd into it
        echo "Switching to worktree $target_branch" >&2
        cd "$dir" || return 1
    else
        # Create the worktree (but branch currently already exist)
        local root_dir
        root_dir=$(dirname "$DOT_GIT_MAIN_FOLDER")
        local worktree_path="$root_dir/$target_branch"
        echo "Creating worktree for $target_branch" >&2
        git worktree add "$worktree_path" "$target_branch" || return 1
        cd "$worktree_path" || return 1
    fi

    echo "$current_branch" > "$OLD_BRANCH_FILE"
}

_gsw_resolve_branch() {
    local target_branch=""

    if [[ $# -eq 0 ]]; then
        local selection
        selection=$(git for-each-ref --format='%(refname:short)' refs/heads/ 2>/dev/null)
        selection="$selection"$'\n'"-"
        selection="$selection"$'\n'"--"
        target_branch=$(echo "$selection" | fzf)
    else
        target_branch="$1"
    fi

    # Special cases (git switch -)
    if [ "$target_branch" = "-" ]; then
        target_branch=$(cat "$OLD_BRANCH_FILE" 2>/dev/null)
    elif [ "$target_branch" = "--" ]; then
        target_branch=$(git rev-parse --abbrev-ref @{-1} 2>/dev/null) || target_branch=''
    fi

    if [ -z "$target_branch" ]; then
        echo "No branch were given." >&2
        return 1
    fi

    if ! git show-ref --verify --quiet "refs/heads/$target_branch"; then
        echo "The branch $target_branch doesnt exist." >&2
        return 1
    fi

    echo "$target_branch"
}

_gsw_create() {
    local new_branch="$1"
    if [ -z "$new_branch" ]; then
        echo "No branch name given." >&2
        return 1
    fi

    if git show-ref --verify --quiet "refs/heads/$new_branch"; then
        echo "The branch $new_branch already exists." >&2
        return 1
    fi

    local root_dir
    root_dir=$(dirname "$DOT_GIT_MAIN_FOLDER")
    local worktree_path="$root_dir/$new_branch"
    echo "Creating branch and worktree for $new_branch" >&2
    git worktree add -b "$new_branch" "$worktree_path" || return 1

    _gsw_switch "$new_branch"
}

_gsw_delete() {
    local del_branch="$1"
    if [ -z "$del_branch" ]; then
        echo "No branch name given." >&2
        return 1
    fi

    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD)

    local dir
    dir=$(git worktree list | awk -v branch="[$del_branch]" '$3==branch {print $1; exit 0}')
    if [ -z "$dir" ]; then
        echo "No worktree found for branch $del_branch." >&2
        return 1
    fi

    if [ "$del_branch" = "$current_branch" ]; then
        echo "Cannot delete the worktree you are currently in." >&2
        return 1
    fi

    echo "Removing worktree for $del_branch" >&2
    git worktree remove "$dir" || return 1
}

function gsw() {
    if ! git rev-parse --is-inside-work-tree > /dev/null; then
        return 1
    fi

    local DOT_GIT_MAIN_FOLDER
    DOT_GIT_MAIN_FOLDER=$(realpath $(git rev-parse --git-common-dir 2>/dev/null))
    local OLD_BRANCH_FILE="$DOT_GIT_MAIN_FOLDER/gsw-old-branch.txt"

    local mode='switch'
    if [ "$1" = "-c" ]; then
        mode='create'
        shift
    elif [ "$1" = "-d" ]; then
        mode='delete'
        shift
    fi

    case "$mode" in
        create) _gsw_create "$1" ;;
        delete) _gsw_delete "$1" ;;
        switch)
            local target_branch
            target_branch=$(_gsw_resolve_branch "$@") || return 1
            _gsw_switch "$target_branch"
            ;;
    esac
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
