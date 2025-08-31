#! /bin/bash

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
logFile=/config/"$channelsHost"-"$channelsPort"_comskipignore_latest.log
channel=$2
curlAction=$3

echo "Channel $channel had its Comskip status changed via a curl -X $curlAction on $dvr:\n" > $logFile
curl -X $curlAction http://$dvr/comskip/ignore/channel/$channel >> $logFile
cat $logFile
