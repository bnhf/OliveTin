#!/bin/bash

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
runInterval=$2
healthchecksIO=$3
logFile=/config/"$channelsHost"-"$channelsPort"_pingcdvr_latest.log
runFile=/tmp/"$channelsHost"-"$channelsPort"_pingcdvr.run

while true; do
  #pingDVR=$(ping -q -c 1 -W 2 $channelsHost)
  curlDVR=$(curl --fail --output /dev/null --max-time 5 -w "HTTP Status: %{http_code}\nEffective URL: %{url_effective}\n" http://$dvr 2>&1)

  [[ $? -eq 0 && -n $healthchecksIO ]] \
    && curl -m 10 --retry 5 $healthchecksIO

  #{ printf "\n%s" "$(date)"; echo "$pingDVR" | sed '/^$/d' | sed 's/PING/\nPING/'; } >> $logFile
  { printf "\n%s" "$(date)"; echo -e "\n$curlDVR"; } >> $logFile

  touch $runFile
  [[ $runInterval == "once" ]] \
    && exit 0 \
    || sleep $runInterval
done