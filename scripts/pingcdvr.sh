#!/bin/bash
# pingcdvr.sh
# 2026.06.05

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
runInterval=$2
healthchecksIO=$3
logFile=/config/"$channelsHost"-"$channelsPort"_pingcdvr_latest.log
logTemp=/tmp/"$channelsHost"-"$channelsPort"_pingcdvr_latest.log
  [[ -f $logTemp ]] && rm $logTemp
logForeground=/tmp/"$channelsHost"-"$channelsPort"_pingcdvr_foreground.log
runFile=/tmp/"$channelsHost"-"$channelsPort"_pingcdvr.run
healthchecksIPFile=/tmp/hc-ping-ip
healthchecksHost=$(echo "$healthchecksIO" | awk -F/ '{print $3}')
firstRun=true

while true; do
  #pingDVR=$(ping -q -c 1 -W 2 $channelsHost)
  curlDVR=$(curl -s --fail --output /dev/null --max-time 5 -w "HTTP Status: %{http_code}\nEffective URL: %{url_effective}\n" http://$dvr 2>&1)

  dvrStatus=$?
  if [[ $dvrStatus -eq 0 && -n $healthchecksIO ]]; then
    healthchecksResult=$(curl -s -m 10 --retry 5 --retry-all-errors --retry-delay 5 \
      -w "\nRemoteIP: %{remote_ip}\nHTTP Status: %{http_code}" \
      --output /dev/null $healthchecksIO 2>&1)
    healthchecksStatus=$?
    if [[ $healthchecksStatus -eq 0 ]]; then
      healthchecksIP=$(echo "$healthchecksResult" | awk -F': ' '/RemoteIP/{print $2}')
      [[ -n $healthchecksIP ]] && echo "$healthchecksIP" > "$healthchecksIPFile"
      healthchecksLog="Healthchecks.io ping OK: $healthchecksResult"
    elif [[ $healthchecksStatus -eq 6 && -f $healthchecksIPFile ]]; then
      healthchecksIP=$(cat "$healthchecksIPFile")
      healthchecksResult=$(curl -s -m 10 --retry 5 --retry-all-errors --retry-delay 5 \
        --resolve "$healthchecksHost:443:$healthchecksIP" \
        -w "HTTP Status: %{http_code}" \
        --output /dev/null $healthchecksIO 2>&1)
      healthchecksStatus=$?
      [[ $healthchecksStatus -eq 0 ]] \
        && healthchecksLog="Healthchecks.io ping OK (used cached IP $healthchecksIP): $healthchecksResult" \
        || healthchecksLog="Healthchecks.io ping FAILED with cached IP $healthchecksIP (exit $healthchecksStatus): $healthchecksResult"
    else
      healthchecksLog="Healthchecks.io ping FAILED (exit $healthchecksStatus): $healthchecksResult"
    fi
  elif [[ -n $healthchecksIO ]]; then
    healthchecksLog="Healthchecks.io ping skipped: DVR unreachable"
  else
    healthchecksLog=""
  fi

  #{ printf "\n%s" "$(date)"; echo "$pingDVR" | sed '/^$/d' | sed 's/PING/\nPING/'; } >> $logFile
  { printf "\n%s" "$(date)"; echo -e "\n$curlDVR"; [[ -n $healthchecksLog ]] && echo "$healthchecksLog"; } >> $logTemp

  [[ "$firstRun" == "true" ]] \
    && { cat "$logTemp" >> "$logForeground"; firstRun=false; } \
    || sed 's/\x1b\[[0-9;]*m//g' "$logTemp" >> "$logFile"

  touch $runFile
  [[ $runInterval == "once" ]] \
    && exit 0

  [[ $runInterval != "once" ]] \
    && rm $logTemp \
    && sleep $runInterval
done
