#!/bin/bash

set -x

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
runInterval=$2
healthchecksIO=$3
recordingLogAge=$(echo "$runInterval" |  sed 's/d//')
[[ $runInterval == "once" ]] && recordingLogAge=30
scriptBaseName=$(basename "$0" | sed 's/.sh//')
logFile=/config/"$channelsHost"-"$channelsPort"_deletelogs_latest.log

dvrDir="$channelsHost-$channelsPort"
[ -z $CHANNELS_DVR_ALTERNATES ] && dvrDir="dvr"

while true; do
  [ -d "/mnt/$dvrDir/Logs/recording" ] \
    && echo "Deleting recording log files for $dvr that are more than $recordingLogAge days old" >> $logFile \
    && find /mnt/$dvrDir/Logs/recording -type d -mtime +$recordingLogAge -exec rm -r {} \; >> $logFile  2>&1
    sed -i 's/No such file or directory/Deleted/g' $logFile

  if [ ! -d "/mnt/$dvrDir/Logs/recording" ]; then
    echo "Your Channels DVR Server's /dvr directory needs to be bound to this container" >> $logFile
    exit 0
  fi

  [[ $runInterval == "once" ]] \
    && exit 0

  [[ -n $healthchecksIO ]] \
    && curl -m 10 --retry 5 $healthchecksIO

  [[ $runInterval != "once" ]] \
    && sleep $runInterval
done