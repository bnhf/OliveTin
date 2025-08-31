#!/bin/bash
# adbpackages.sh
# 2025.05.05

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x

ah4cContainer="$1"

docker exec $ah4cContainer ./adbpackages.sh
