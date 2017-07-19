#!/usr/bin/env bash
#
# Watch the docker images and ps boards.
# Any additional arguments are passed to the ``docker ps`` command.
#
watch -n1 "
echo
echo ':: Images ::'
docker images
echo
echo
echo ':: Containers ::'
docker ps $@
"
