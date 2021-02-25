#!/bin/bash
#docker rmi $(docker images | grep '^<none>' | awk '{print $3}')
mapfile -t IMAGE_LIST < <(docker images --filter "dangling=true" -q --no-trunc)
if [[ "${#IMAGE_LIST[@]}" -eq 0 ]]
then
    echo "No dangling images to remove."
    exit 0
fi
echo "Attempting to remove ${#IMAGE_LIST[@]} dangling images."
docker rmi "${IMAGE_LIST[@]}"
