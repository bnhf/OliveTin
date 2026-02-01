#!/bin/bash
# actionlogs.sh
# 2026.01.18

dvr="$1"
channelsHost=$(echo "$dvr" | awk -F: '{print $1}')
channelsPort=$(echo "$dvr" | awk -F: '{print $2}')
actionName="$2"
[ ! -f /config/${channelsHost}-${channelsPort}_${actionName}_latest.log ] && echo "No log file exists for that Action" && exit 0

ls -l --time-style=+"%Y-%m-%d %H:%M:%S" /config/${channelsHost}-${channelsPort}_${actionName}_latest.log | awk '{for (i=8; i<NF; i++) printf $i " "; print $(NF) " " $(6) " " $(7)}'
echo
cat /config/${channelsHost}-${channelsPort}_${actionName}_latest.log
