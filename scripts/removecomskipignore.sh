#!/bin/bash
# removecomskipignore.sh
# 2026.01.18

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x
greenEcho() { echo -e "\033[0;32m$1\033[0m ${*:2}"; }

channel=$1

curl -s -XDELETE http://$CHANNELS_DVR/comskip/ignore/channel/$channel
