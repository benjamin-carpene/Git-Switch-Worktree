# Description

Git Switch Worktree (GSW) is a simple yet powerfull git utility used for navigating between git worktrees.
It enables the user to navigate in worktrees using `gsw` in the same way as they would use `git switch` in a bare repository.

# Features

- Navigate through worktree directories for a given repository
- Still works like a charm on bare repo
- Uses FZF's TUI for choosing a worktree wen no argument given
- Has a 'last worktree' feature (`gsw -`) for switching to the last worktree
    - Works on a **PER REPOSITORY** basis, to not mix oranges and apples
    - You can still use `gsw --` if you want to use the default `git switch -` option


# Synopsis

`gsw [BRANCH]`
- With `[BRANCH]` the optional argument branch that we will switch to
- If no branch is given, FZF's TUI is used for the user to choose his branch
- If the branch is a worktree, `gsw` switches to it (goes to the right directory)
- If the selected branch is not a worktree, `gsw` simply switches to it as a regular `git switch` command

# Dependencies
- `git` (obviously)
- `fzf` for the TUI
- That's all 😀

# Installation

Run the `./install.sh` script on this repo, which installs the script in `~/.local/bin`.
- It will ask you if you want to create an alias, if (*like me*) you already had a `gsw` alias for git switch.
- It will also recommend you to update your `PATH` variable if necessary.
