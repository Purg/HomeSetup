#!/bin/bash
#docker rmi $(docker images | grep '^<none>' | awk '{print $3}')
docker rmi $(docker images --filter "dangling=true" -q --no-trunc)
