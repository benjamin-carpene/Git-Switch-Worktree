DEBUG=true
function _gsw_log_dbg() {
    if [ "$DEBUG" = "true" ]; then
        echo "DBG: $@" >&2
    fi
}

function _gsw_branch_exists() {
    local branch="$1"
    git show-ref --verify --quiet "refs/heads/$branch"
    return $?
}

function _gsw_get_dir_from_branch() {
    local branch="$1"
    git worktree list | awk -v branch="[$branch]" '$3==branch {print $1; exit 0}'
}

function _gsw_usage() {
    echo -e "gsw - a simple git switch worktree utility"
    echo -e "Synopsis:"
    echo -e "  gsw --help : help section"
    echo -e "  gsw [BRANCH_NAME] : The main command, switches to the given branch if given, otherwise uses fzf for selecting a branch"
    echo -e "  gsw --create <DIR_PATH> [BRANCH_NAME] : Create a worktree a for BRANCH_NAME under DIR_PATH"
    echo -e "  gsw --delete [BRANCH_NAME] : Delete the given BRANCH_NAME worktree AND branch"
}

function _gsw_parse_args() {
    SHORTOPTS="hc:d"
    LONGOPTS="help,create:,delete"

    local parse_opts='true' # No need to parse if we have thisa argument, quickfix
    if [ "$1" = '--' ]; then
        parse_opts='false'
    fi

    if [ "$parse_opts" = 'true' ]; then
        _gsw_log_dbg "parse_opts: $parse_opts"
        # Parsing options
        PARSED=$(getopt --options=$SHORTOPTS --longoptions=$LONGOPTS --name "$0" -- "$@")
        if [[ $? -ne 0 ]]; then
            return 1
        fi
        eval set -- "$PARSED"

        # Process options
        while true; do
            case "$1" in
                -h|--help)
                    _gsw_usage
                    shift
                    return 255 # Special code for "worked but stops"
                    ;;
                -c|--create)
                    _gsw_mode='CREATE'
                    _gsw_cr_dir="$2"
                    shift 2
                    ;;
                -d|--delete)
                    _gsw_mode='DELETE'
                    shift
                    ;;
                --)
                    shift
                    break # In our case we want to treat it like a value, so we just break
                    ;;
                *)
                    echo "Unexpected option: $1"
                    return 1
                    ;;
            esac
        done
    fi

    # Remaining arg as _gsw_branch
    _gsw_branch="$1"

    # If nothing given use FZF for interactive selections
    if [ -z "$_gsw_branch" ]; then
        local selection=$(git for-each-ref --format='%(refname:short)' refs/heads/ 2>/dev/null) # Git branches
        selection="$selection"$'\n'"-" # -
        selection="$selection"$'\n'"--" # --
        _gsw_branch=$(echo "$selection" | fzf)
    fi

    # Sanitization
    if [ -z "$_gsw_branch" ]; then
        echo "No branch were given." >&2
        return 1
    fi

    _gsw_log_dbg "_gsw_branch: $_gsw_branch"
}

function _gsw_switch() {
    _gsw_log_dbg 'In switch mode'

    # Variables for old-branch file
    DOT_GIT_MAIN_FOLDER=$(realpath $(git rev-parse --git-common-dir 2>/dev/null))
    OLD_BRANCH_FILE="$DOT_GIT_MAIN_FOLDER/gsw-old-branch.txt"

    # Keep the current origin branch in memory
    local current_branch=$(git rev-parse --abbrev-ref HEAD)

    # Special cases (git switch -)
    if [ "$_gsw_branch" = "-" ]; then
        _gsw_branch=$(cat "$OLD_BRANCH_FILE" 2>/dev/null)
    elif [ "$_gsw_branch" = "--" ]; then # Use the regular last branch (worktree specific)
        _gsw_branch=$(git rev-parse --abbrev-ref @{-1} 2>/dev/null) || _gsw_branch=''
    fi
    _gsw_log_dbg "Branch to switch : $_gsw_branch"

    if ! _gsw_branch_exists "$_gsw_branch"; then
        echo "The branch $_gsw_branch doesnt exist." >&2
        return 1
    fi

    if [ "$_gsw_branch" = "$current_branch" ]; then
        return 0 # Nothing to do
    fi

    # Get the folder
    local dir=$(_gsw_get_dir_from_branch "$_gsw_branch")

    if [ -n "$dir" ]; then
        echo "Switching to worktree $_gsw_branch" >&2
        cd "$dir" || return 1 # CD into the worktree
    else
        git switch "$_gsw_branch" || return 1
    fi

    # Update OLD_BRANCH_FILE
    echo "$current_branch" > "$OLD_BRANCH_FILE"
}

function _gsw_create() {
    _gsw_log_dbg 'In create mode'

    if _gsw_branch_exists "$_gsw_branch"; then
        # Adds the worktree for the existing branch
        git worktree add "$_gsw_cr_dir" "$_gsw_branch"
    else
        # Adds the worktree for the created branch
        git worktree add "$_gsw_cr_dir" -b "$_gsw_branch"
    fi
}

function _gsw_delete() {
    _gsw_log_dbg 'In delete mode'

    if ! _gsw_branch_exists "$_gsw_branch"; then
        echo "The branch $_gsw_branch doesnt exist." >&2
        return 1
    fi

    # Finds the directory for removing the worktree
    local dir=$(_gsw_get_dir_from_branch "$_gsw_branch")

    if [ -n "$dir" ]; then
        # Delete the worktree
        git worktree remove "$dir"

        # Remove the branch if accepted
        echo "Do you want to also remove the branch ? ( y / [n] )"
        read _gsw_answer
        if [ "$_gsw_answer" = "y" ] || [ "$_gsw_answer" = "Y" ]; then
            echo "Removing branch $_gsw_branch"
            git branch -d "$_gsw_branch"
        fi
    fi
}

function gsw() {
    # Enter its not a worktree or a base repo and exits
    if ! git rev-parse --is-inside-work-tree > /dev/null; then
        return 1
    fi

    # gsw variables
    _gsw_mode='SWITCH'
    _gsw_cr_dir=''
    _gsw_branch=''

    # Parse arguments and then sanitize
    _gsw_parse_args "$@"
    local err_code="$?"
    if [ "$err_code" -eq 255 ]; then
        return 0
    fi
    if [ "$err_code" -ne 0 ]; then
        return 1
    fi

    case "$_gsw_mode" in
        SWITCH) _gsw_switch;;
        CREATE) _gsw_create;;
        DELETE) _gsw_delete;;
        *) echo "Unexpected _gsw_mode: $_gsw_mode"; return 1;;
    esac
}

# For people who already had an alias :)
alias gsw=gsw
