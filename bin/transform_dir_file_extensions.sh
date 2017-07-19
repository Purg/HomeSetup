#!/usr/bin/env bash
#
# Script to add the file extensions of a directory of image files based on
# the reported output of ``file`` and using GNU parallel.
#
# Arguments should be directory root locations where files are located
# (passed directly to ``find``).
# Files should be backed up before using this tool.
# Will try to rename ALL files underneath specified directories.
#
# Requires GNU parallel.
#
find "$@" -type f \
  | parallel '
    ext="$(file "{}" | sed -re "s|.* (\\w+) image data.*|\\1|" | tr "[:upper:]" "[:lower:]")"
    target="{}.$ext"
    mv "{}" "$target"
    ls -lh "$target"
'
