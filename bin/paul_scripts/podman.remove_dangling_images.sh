#!/bin/bash
#podman rmi $(podman images | grep '^<none>' | awk '{print $3}')
mapfile -t IMAGE_LIST < <(podman images --filter "dangling=true" -q --no-trunc)
if [[ "${#IMAGE_LIST[@]}" -eq 0 ]]
then
    echo "No dangling images to remove."
    exit 0
fi
echo "Attempting to remove ${#IMAGE_LIST[@]} dangling images."
podman rmi "${IMAGE_LIST[@]}"
