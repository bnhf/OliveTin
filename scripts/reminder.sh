#!/bin/bash
# reminder.sh
# 2025.03.05

set -x

dvr="$1"
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
logFile=/config/"$channelsHost"-"$channelsPort"_reminder_latest.log
  [[ -f $logFile && $PERSISTENT_LOGS != "true" ]] && rm $logFile

frequency="$2"
  matchRange=$(( ($frequency * 60) / 2 ))
  checkInterval=$(($frequency * 60))
paddingSeconds=$3
read -a appriseURLs <<< "$4"
deleteJob="$5"
checkExtra="$6"
checkExtra="${checkExtra:-10}"
channelChangeClient=$7

eventReminder() {
  while true; do
    timeNow=$(date +%s)
    nextRun=$(($timeNow + $checkInterval))
    channelChange=$(curl -s http://$dvr/api/v1/jobs | jq ".[] | select((.duration % 60 == 40) and (.start_time >= (${timeNow}) and .start_time <= (${timeNow} + ${checkInterval} + ${checkExtra})))")
    sendReminder=$(curl -s http://$dvr/api/v1/jobs | jq ".[] | select(((.duration % 60 == ${paddingSeconds}) or (.duration % 60 == 40)) and (.start_time >= (${timeNow}) and .start_time <= (${timeNow} + ${checkInterval} + ${checkExtra})))")
    echo "$(date +"%Y-%m-%d %H:%M:%S") - Checking for DVR jobs set to start in the next $(($checkInterval / 60)) minutes with ${paddingSeconds} second padding..." >> $logFile

    if [[ -n $sendReminder ]]; then
      echo "$sendReminder" >> $logFile
      eventName=$(echo "$sendReminder" | jq -r '.name')
      eventStartTime=$(echo "$sendReminder" | jq -r '.start_time' | awk '{print $1 + "'"$paddingSeconds"'"}' | while read -r epoch; do date -d @"$epoch" +"%H:%M"; done)
      eventChannels=$(echo "$sendReminder" | jq -r '.channels | join(", ")')
      channelChangeNumber=$(echo "$channelChange" | jq -r '.channels[0]' | awk '{print $1}')
      channelChangeTime=$(echo "$channelChange" | jq -r '.start_time' | awk '{print $1}')
      
      reminderMessage=$(printf "Event: %s\nStart Time: %s\nChannels: %s" "$eventName" "$eventStartTime" "$eventChannels")

      for appriseURL in "${appriseURLs[@]}"; do
        case "$appriseURL" in
          channels://*)
            reminderTimeout="${appriseURL#channels://}"
            reminderTimeout="${reminderTimeout:-40}"
            /config/notifications.sh "Reminder" "$reminderMessage" "$reminderTimeout" && echo "$(date +"%Y-%m-%d %H:%M:%S") - Notification(s) sent via Channels API" >> $logFile
            ;;
          olivetin://)
            apprise -t "Reminder" -b "$reminderMessage" mailtos://${ALERT_EMAIL_FROM%@*}:$ALERT_EMAIL_PASS@${ALERT_EMAIL_FROM#*@}@$ALERT_SMTP_SERVER?to=$ALERT_EMAIL_TO && echo "$(date +"%Y-%m-%d %H:%M:%S") - Notification(s) sent via OliveTin alerts" >> $logFile
            ;;
          *)
            apprise -t "Reminder" -b "$reminderMessage" "$appriseURL" && echo "$(date +"%Y-%m-%d %H:%M:%S") - Notification(s) sent via Apprise" >> $logFile
            ;;
        esac
      done
      
      [[ "$deleteJob" == "true" ]] && { echo "$sendReminder" | jq -r '.id' | while read -r eventID; do curl -s -X DELETE http://$dvr/dvr/jobs/$eventID; echo "$(date +"%Y-%m-%d %H:%M:%S") - DVR job $eventID deleted" >> $logFile; done }
      [[ -n "$channelChange" ]] && channelChanger &
    fi

    #sleepInterval=$(($nextRun - $(date +%s)))
    #sleep "$sleepInterval"
    minuteMarkSleep
  done
}

channelChanger() {
  sleep $(($channelChangeTime - $(date +%s)))
  curl -s -X POST http://$channelChangeClient:57000/api/play/channel/$channelChangeNumber \
    && curl -v --header "Content-Type: application/json" http://$channelChangeClient:57000/api/notify -d '{"title": "Requested", "message": "Channel change to '"$channelChangeNumber"'", "timeout": 120}' \
    && echo "$(date +"%Y-%m-%d %H:%M:%S") - Channel changed to $channelChangeNumber on $channelChangeClient" >> $logFile
}

minuteMarkSleep() {
  case "$frequency" in
     5) minuteMarks=(0 5 10 15 20 25 30 35 40 45 50 55) ;;
    10) minuteMarks=(0 10 20 30 40 50) ;;
    20) minuteMarks=(0 20 40) ;;
    30) minuteMarks=(0 30) ;;
  esac

  currentMinute=$(date +%M)
  currentSecond=$(date +%S)

  unset nextMark
  for mark in "${minuteMarks[@]}"; do
    (( 10#$mark > 10#$currentMinute )) && { nextMark=$mark; break; }
  done
  : "${nextMark:=${minuteMarks[0]}}"

  sleep $((( (nextMark + 60 * (nextMark < 10#$currentMinute) ) - 10#$currentMinute) * 60 - 10#$currentSecond))
}

main() {
  eventReminder
}

main
