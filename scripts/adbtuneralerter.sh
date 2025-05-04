#!/bin/bash
# adbtuneralerter.sh
# 2025.05.02

#set -x

dvr="$1"
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
runInterval="$2"
  [[ "$runInterval" == "0" ]] && runInterval=""
logFile=/config/"$channelsHost"-"$channelsPort"_adbtuneralerter_latest.log
  [[ -f $logFile && $PERSISTENT_LOGS != "true" ]] && rm $logFile
adbtunerHostPort="$3"
appriseURL="$4"
  [[ "$appriseURL" == "none" ]] && appriseURL=""

adbtunerAlerts() {
  while true; do
    adbtunerStatus=$(curl -s http://$adbtunerHostPort/up)
    #adbtunerStatus=$(echo "$adbtunerStatus" | sed s/true/false/g) # Change true to false for testing
    adbtunerNotConnected=$(echo "$adbtunerStatus" | jq 'map(select(.device_connected != true or .streaming_endpoint_connected != true))[]')

    if [[ -n "$adbtunerNotConnected" && -z "$appriseURL" ]]; then
      {
        echo -e "Subject: OliveTin ADBTuner Alert for $dvr\n"
        echo -e "One or more ADBTuner devices at $adbtunerHostPort ($dvr) are not connected or are unauthorized:\n"
        echo "$adbtunerStatus"
      } | msmtp -a default $ALERT_EMAIL_TO
      echo "$(date +"%Y-%m-%d %H:%M:%S") - Notification(s) sent via OliveTin ALERT_EMAIL" >> "$logFile"
    elif [[ -n "$adbtunerNotConnected" && -n "$appriseURL" ]]; then
      apprise -t "OliveTin ADBTuner Alert for $dvr" -b "One or more ADBTuner devices are reporting an issue: $adbtunerStatus" "$appriseURL" && echo "$(date +"%Y-%m-%d %H:%M:%S") - Notification(s) sent via Apprise" >> "$logFile"
    elif [[ "$(echo "$adbtunerStatus" | jq -e 'type == "array"')" != "true" ]]; then
      echo "$(date +"%Y-%m-%d %H:%M:%S") - Invalid JSON received from $adbtunerHostPort" >> "$logFile"
    else
      echo "$(date +"%Y-%m-%d %H:%M:%S") - All ADBTuner devices are reporting connected" >> "$logFile"
    fi

    sleep "$runInterval"
  done
}

main() {
  adbtunerAlerts
}

main
