#!/bin/bash

#set -x

dvr="$1"
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
runInterval="$2"
  [[ "$runInterval" == "0" ]] && runInterval=""
logFile=/config/"$channelsHost"-"$channelsPort"_adbalerter_latest.log
ah4cContainer="$3"

adbAlerts() {
  adbDevices=$(docker exec $ah4cContainer adb devices)
  adbNotConnected=$(echo "$adbDevices" | tail -n +2 | awk '{ if ($NF != "device") print $0 }')

  while true; do
    if [ -n "$adbNotConnected" ]; then {
      echo -e "Subject: OliveTin ADB Alert for $dvr\n"
      echo -e "The following ADB devices in your $ah4cContainer ($dvr) are not connected or are unauthorized:\n"
      echo "$adbNotConnected"
      } | msmtp -a default $ALERT_EMAIL_TO
    fi

    sleep $runInterval
  done
}

main() {
  adbAlerts
}

main
