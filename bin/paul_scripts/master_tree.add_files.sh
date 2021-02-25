#!/usr/bin/env bash
#
# Use: master_tree.add_images.sh IMPORT_DIR [IMPORT_DIR ...]
#
# Script to add images (or other files) to a "master" store directory tree.
#
# Requires:
# - GNU parallel
#
# This script should be linked in the directory where the master directory
# is intended to live.
#
# Input to this script should be directories or files like would be given to
# the ``find`` command.
#
# If given existing images, they are not copied again. We only check that the
# target file already exists as compared to the input file's SHA1 checksum.
#
SCRIPT_DIR="$(cd "$(dirname ${BASH_SOURCE[0]})" && pwd)"
MASTER_DIR_BASE="${SCRIPT_DIR}/master_tree"

# The if-statement checks if the file exists and is not different from the
# input. Thus, if the target does not exist, or the input and target are
# different, then copy the target file into the tree. The input/target file
# might be different if there was an error copying in the file in the first
# place.
find "$@" -type f | parallel "
SHA1=\$(sha1sum {} | cut -d' ' -f1)
SHA1_p1=\$(echo \$SHA1 | cut -c 1-4)
SHA1_p2=\$(echo \$SHA1 | cut -c 5-8)
SHA1_p3=\$(echo \$SHA1 | cut -c 9-12)
SHA1_p4=\$(echo \$SHA1 | cut -c 13-16)
SHA1_p5=\$(echo \$SHA1 | cut -c 17-20)
SHA1_p6=\$(echo \$SHA1 | cut -c 21-24)
SHA1_p7=\$(echo \$SHA1 | cut -c 25-28)
SHA1_p8=\$(echo \$SHA1 | cut -c 29-32)
SHA1_p9=\$(echo \$SHA1 | cut -c 33-36)
TARGET=${MASTER_DIR_BASE}/\$SHA1_p1/\$SHA1_p2/\$SHA1_p3/\$SHA1_p4/\$SHA1_p5/\$SHA1_p6/\$SHA1_p7/\$SHA1_p8/\$SHA1_p9/\$SHA1

if [ -f \$TARGET ] && (diff \$TARGET {} &>/dev/null)
then
  echo \"Existing: '\$TARGET'\"
else
  mkdir -p \"\$(dirname \$TARGET)\"
  cp {} \$TARGET
  echo \"Copied  : '\$TARGET'\"
fi
"
