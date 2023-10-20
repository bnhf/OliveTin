#!/bin/bash

#set -x

runInterval=$1
healthchecksIO=$2
recordingLogAge=$(echo "$runInterval" |  sed 's/d//')
[[ $runInterval == "once" ]] && recordingLogAge=30
scriptBaseName=$(basename "$0" | sed 's/.sh//')

while true; do
  [ -d "/mnt/dvr/Logs/recording" ] \
    && find /mnt/dvr/Logs/recording -type d -mtime +$recordingLogAge -exec rm -r {} \; > /config/$scriptBaseName.log  2>&1
    sed -i 's/No such file or directory/Deleted/g' /config/$scriptBaseName.log

  if [ ! -d "/mnt/dvr/Logs/recording" ]; then
    echo "Your Channels DVR Server's /dvr directory needs to be bound to this container" > /config/$scriptBaseName.log
    exit 0
  fi

  [[ $runInterval == "once" ]] \
    && exit 0

  [[ -n $healthchecksIO ]] \
    && curl -m 10 --retry 5 $healthchecksIO

  [[ $runInterval != "once" ]] \
    && sleep $runInterval
done