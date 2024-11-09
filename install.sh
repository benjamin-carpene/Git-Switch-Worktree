#!/bin/env bash

if [ -n $HOME ]; then
    # Installs the script
    local_install_dir="$HOME/.local/gsw"
    mkdir -p "$local_install_dir"
    cp gsw.sh "$local_install_dir/gsw.sh"

    local_bin_dir="$HOME/.local/bin"
    mkdir -p "$local_bin_dir"
    ln -sf "$local_install_dir/gsw.sh" "$local_bin_dir/gsw"

    echo "gsw has been installed in $local_install_dir with a symlink in $local_bin_dir"

    if [[ "$PATH" != *"$local_bin_dir"* ]]; then
        echo "You may not have $local_bin_dir in your PATH variable, which is necessary for gsw."
        echo "Type \`echo 'PATH=\$PATH:$local_bin_dir' >> $HOME/.bashrc\` in order to add it to your path."
    fi
else
    echo "User has no HOME folder"
    exit 1
fi
