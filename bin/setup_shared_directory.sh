#!/bin/bash
#
# Knowledge dump of how to setup a directory's group permissions and ACLs.
#
dirname="${1}"
groupname="${2}"

dirpath="/data/shared/${dirname}"

mkdir -p "${dirpath}"
echo "Chowning all files"
chown -R root:$2 "${dirpath}"
echo "Adding sticky bit to directories"
find "${dirpath}" -type d | xargs -n 16 chmod g+s
echo "Adding ACL rules"
# Defaut group ownership to rwx for dirs (rw- for files)
# and no permissions for other.
setfacl -R -m g:${groupname}:7,o:0 -dm g:${groupname}:7,o:0 "${dirname}"
