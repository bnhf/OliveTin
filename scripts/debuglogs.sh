#/bin/bash
# debuglogs.sh
# 2025.07.08

actionName="$1"
[ ! -f /config/$actionName.debug.log ] && echo "No debug log file exists for that Action" && exit 0

ls -l --time-style=+"%Y-%m-%d %H:%M:%S" /config/$actionName.debug.log | awk '{for (i=8; i<NF; i++) printf $i " "; print $(NF) " " $(6) " " $(7)}'
echo
cat /config/$actionName.debug.log
