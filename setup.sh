#!/bin/bash

#
# Script for setting up the contents of the .local tree into a linux userspace.
# (backs up and existing files when found)
#

now=$(date +"%Y-%m-%d_%H-%M-%S")
my_home="${HOME}"

cd "${my_home}"

# Helper function "installing" a link in the home directory
#
# Usage:
#   backup_and_link <source> <target>
#
# Where "source" is a file in the $HOME/.local/etc/linux-home/ directory and
# "target" is the target file to be placed in the $HOME directory.
#
function backup_and_link() {
  source="$1"
  target="$2"
  echo "Linking ${my_home}/${target} -> .local/etc/linux-home/${source}"
  [ -f "${my_home}/${target}" -o -d "${my_home}/${target}" ] \
    && echo "-- Backing up existing file: ${my_home}/${target} -> ${my_home}/${target}.${now}" \
    && mv "${my_home}/${target}" "${my_home}/${target}.${now}"
  ln -s ".local/etc/linux-home/${source}" "${my_home}/${target}"
}

#
# Link pertinent files in the ${my_home} directory.
#
backup_and_link bashrc .bashrc
backup_and_link bash_aliases .bash_aliases
backup_and_link bash_profile .bash_profile
backup_and_link bash_logout .bash_logout
backup_and_link emacs .emacs
backup_and_link gitconfig .gitconfig
backup_and_link gitignore.global .gitignore.global
backup_and_link tmux.conf .tmux.conf
backup_and_link vimrc .vimrc
backup_and_link vim .vim

