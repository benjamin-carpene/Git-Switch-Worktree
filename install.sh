#!/bin/env bash

if [ -n $HOME ]; then
    type gsw &>/dev/null && set_alias_msg='true' # if something with that name already exist

    # Installs the script
    local_install_dir="$HOME/.local/share"
    mkdir -p "$local_install_dir"
    cp gsw.sh "$local_install_dir/gsw.sh"

    echo "gsw has been installed in $local_install_dir"
    echo

    # Ceck source in bashrc / zshrc
    source_cmd="source $local_install_dir/gsw.sh"
    
    # Handles for bashrc
    if which bash &>/dev/null && ! grep -Fq "$source_cmd" "$HOME/.bashrc"; then
        echo "You might want to source the gsw script in your bashrc for accessing gsw"
        echo "Type \`echo '$source_cmd' >> $HOME/.bashrc\` or add it by yourself"
        echo
    fi

    # Handles for zshrc
    if which zsh &>/dev/null && ! grep -Fq "$source_cmd" "$HOME/.zshrc"; then
        echo "You might want to source the gsw script in your zshrc for accessing gsw"
        echo "Type \`echo '$source_cmd' >> $HOME/.zshrc\` or add it by yourself"
        echo
    fi
else
    echo "User has no HOME folder"
    exit 1
fi
