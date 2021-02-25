#!/usr/bin/env bash
#
# Simple script for showing the names of projects that have been entered for
# any task in history.
#
task information | awk '{print $1, $2}' | egrep '^Project' | sort | uniq
