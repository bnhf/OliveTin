#! /bin/bash

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
logFile=/config/"$channelsHost"-"$channelsPort"_restartshutdown_latest.log
urlAction=$2

echo -e "The following restart or shutdown action is being sent to $dvr: $urlAction \n" > $logFile
curl -XPUT http://$dvr/updater/$urlAction >> $logFile
cat $logFile
