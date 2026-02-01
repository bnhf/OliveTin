#!/bin/bash
# listgreenicons.sh
# 2026.01.22

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x

cat /config/config.yaml | grep channels.png | awk -F# '{print $2}' | awk '{print $1}'
