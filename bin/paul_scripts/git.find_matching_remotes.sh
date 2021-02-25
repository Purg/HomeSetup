#!/bin/bash

#
# Find branches on a git remote that have zero differences with the current
# HEAD, printing those branches to the terminal.
#

remote_branches=$(git branch -a | grep -v "HEAD" | grep "remotes/")
for branch in ${remote_branches}
do
  diff_length=$(git diff HEAD..${branch} | wc -l)
  echo "Diff HEAD..${branch} -> ${diff_length}"
  if [ ${diff_length} -eq 0 ]
  then
    echo
    echo "Current head matches remote branch: ${branch}"
    echo
    exit 0
  fi
done
exit 1
