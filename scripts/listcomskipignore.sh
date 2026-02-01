#!/bin/bash
# listcomskipignore.sh
# 2026.01.16

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
logFile=/config/"$channelsHost"-"$channelsPort"_comskipignore_latest.log

echo -e "These channels have Comskip disabled on $dvr:\n" > $logFile
curl -s http://$dvr/settings \
  | jq 'to_entries | map(select(.key | test("comskip.ignore.channel.\\d+"))) | from_entries' >> $logFile
cat $logFile
