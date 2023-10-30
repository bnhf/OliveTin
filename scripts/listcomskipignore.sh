#! /bin/bash

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
logFile=/config/"$channelsHost"-"$channelsPort"_comskipignore_latest.log

echo -e "These channels have Comskip disabled on $dvr:\n" > $logFile
curl http://$dvr/settings \
  | jq 'to_entries | map(select(.key | test("comskip.ignore.channel.\\d+"))) | from_entries' >> $logFile
cat $logFile
