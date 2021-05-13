#!/bin/bash
set -e

pkg_arr=()
while read -r line
do
  pkg_arr+=( "$line" )
done < <(
  pip list --format json | jq .[].name -r | grep -Ev '^(pip|setuptools|wheel)$'
)
if [[ "${#pkg_arr[@]}" -gt 0 ]]
then
  echo "Will pip uninstall ${#pkg_arr[@]} packages:"
  echo
  for p in "${pkg_arr[@]}"
  do
    echo "  $p"
  done
  echo
  read -p "Are you sure? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    pip uninstall -y "${pkg_arr[@]}"
  else
    echo "Exiting unchanged."
  fi
else
  echo "Nothing to extra to uninstall."
fi
