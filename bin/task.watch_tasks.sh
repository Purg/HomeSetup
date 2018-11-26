#!/usr/bin/env bash

# Sleep time in seconds between task reports.
SLEEP_AMOUNT=0.5

while [ 1 ]
do
  clear
  date
  task status
  task summary
  sleep ${SLEEP_AMOUNT}
done
