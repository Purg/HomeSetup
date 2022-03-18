#!/bin/bash

#
# Script for setting up the contents of the .local tree into a linux userspace.
# (backs up and existing files when found)
#

now=$(date +"%Y-%m-%d_%H-%M-%S")
my_home="${HOME}"
home_python_req="${my_home}/.local/requirements.txt"

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
  # Bad stuff happens if $1 or $2 are empty
  if [ -z "$1" ]
  then
    echo "ERROR: Source file name missing"
    return -1
  fi
  if [ -z "$2" ]
  then
    echo "ERROR: Target filename missing"
    return -1
  fi

  source=".local/etc/linux-home/$1"
  target="${my_home}/$2"
  echo "${target} -> ${source}"

  # echo "Linking ${target} -> ${source}"

  # Check if the target is currently a link and is referencing the given
  # source.
  if [ -L "${target}" -a "$(readlink ${target})" = "${source}" ]
  then
    echo "-- Link already exists"
  else
    # If the target already exists as a file or directory, back it up.
    if [ -f "${target}" -o -d "${target}" ]
    then
      backup_target="${target}.${now}"
      echo "-- Backing up existing file: ${target} -> ${backup_target}"
      mv "${target}" "${backup_target}"
    fi

    echo "-- Linking"
    ln -s "${source}" "${target}"
  fi
}


#
# Link pertinent files in the ${my_home} directory.
#
backup_and_link bashrc .bashrc
backup_and_link inputrc .inputrc
backup_and_link bash_aliases .bash_aliases
backup_and_link bash_profile .bash_profile
backup_and_link bash_logout .bash_logout
backup_and_link emacs .emacs
backup_and_link gitconfig .gitconfig
backup_and_link gitignore.global .gitignore.global
backup_and_link tmux.conf .tmux.conf
backup_and_link tmux .tmux
backup_and_link vimrc .vimrc
backup_and_link vim .vim

#
# Vundle install
#
vim +PluginInstall +qall

#
# Install user-space python packages
#
pip install --user -r "${home_python_req}"
