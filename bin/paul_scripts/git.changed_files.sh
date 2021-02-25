#!/usr/bin/env bash
#
# Helper script to show the paths to files that have changed between before
# and after points.
#
# Usage: git.changed_files.sh [BEFORE [AFTER]]
#
# If not provided, BEFORE defaults to "master" and AFTER defaults to "HEAD".
#

if [ -n "$1" ]
then
  before="$1"
else
  before="master"
fi

if [ -n "$2" ]
then
  after="$2"
else
  after="HEAD"
fi

git diff ${before}..${after} | grep 'diff --git' | sed -re 's|diff --git a/(.+) b/(.+)|\2|'
