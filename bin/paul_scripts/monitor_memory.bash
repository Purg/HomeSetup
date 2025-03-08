#!/bin/bash
set -e -o pipefail

while true
do
  echo "      date     time     $(free -m | grep total | sed -E 's/^    (.*)/\1/g')"
  echo "$(date '+%Y-%m-%d %H:%M:%S') $(free -m | grep Mem:)"
  echo "                    $(free -m | grep Swap:)"
  sleep 1
done
