#!/bin/bash
# adbalerter.sh
# 2025.05.05

#set -x

dvr="$1"
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
runInterval="$2"
  [[ "$runInterval" == "0" ]] && runInterval=""
logFile=/config/"$channelsHost"-"$channelsPort"_adbalerter_latest.log
  [[ -f $logFile && $PERSISTENT_LOGS != "true" ]] && rm $logFile
ah4cContainer="$3"

adbAlerts() {
  while true; do
    adbDevices=$(docker exec $ah4cContainer adb devices)
    adbNotConnected=$(echo "$adbDevices" | tail -n +2 | awk '{ if ($NF != "device") print $0 }')

    if [ -n "$adbNotConnected" ]; then {
      echo -e "Subject: OliveTin ADB Alert for $dvr\n"
      echo -e "The following ADB devices in your $ah4cContainer ($dvr) are not connected or are unauthorized:\n"
      echo "$adbNotConnected"
      } | msmtp -a default $ALERT_EMAIL_TO
    else
      echo "$(date +"%Y-%m-%d %H:%M:%S") - All ah4c devices are reporting connected" >> "$logFile"
    fi

    sleep $runInterval
  done
}

main() {
  adbAlerts
}

main
