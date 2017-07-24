#!/usr/bin/env bash
#
# Usage: get_file_diffs.sh DIRECTORY BEFORE_HASH AFTER_HASH
#
# Example script to crawl diffs for files under a directory in a git repo
# Need to set hash range.
#
BASE_DIR="${1}"
GIT_BEFORE="${2}"
GIT_AFTER="${3}"

if [ "$#" -ne 3 ]
then
  echo "ERROR: Requires three (3) positional arguments: DIRECTORY BEFORE_HASH AFTER_HASH"
  exit 1
elif [ -z "${BASE_DIR}" ]
then
  echo "ERROR: No base directory"
  exit 1
elif [ -z "${GIT_BEFORE}" ]
then
  echo "ERROR: No before hash"
  exit 1
elif [ -z "${GIT_AFTER}" ]
then
  echo "ERROR: No after hash"
  exit 1
fi

for FILEPATH in $(find "${BASE_DIR}" -type f)
do
  PATCHFILE="$FILEPATH.patch"
  git diff ${GIT_BEFORE}..${GIT_AFTER} -- $FILEPATH >$PATCHFILE
  if [ ! -s "$PATCHFILE" ]
  then
    echo "No diff: $FILEPATH"
    rm $PATCHFILE
  fi
done
