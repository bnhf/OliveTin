#!/bin/bash
# youtube-processor.sh
#2025.01.30

set -x

dvr=$1
channelsHost=$(echo "$dvr" | awk -F: '{print $1}')
channelsPort=$(echo "$dvr" | awk -F: '{print $2}')
frequency=$2
youtube_api_key=$3
apprise_url=$4
  [[ $apprise_url == "olivetin://" ]] && alertUsername="${ALERT_EMAIL_FROM%@*}" && alertDomain="${ALERT_EMAIL_FROM#*@}" \
  && apprise_url="mailtos://$alertUsername:$ALERT_EMAIL_PASS@$alertDomain@$ALERT_SMTP_SERVER?to=$ALERT_EMAIL_TO"
delete_after=$5
video_directory=$6
channels_directory=$7
logFile=/config/"$channelsHost"-"$channelsPort"_youtube-processor_latest.log
configTubeArchivist=/config/"$channelsHost"-"$channelsPort"_data/config.txt

createConfig() {
  cat << EOF > $configTubeArchivist
VIDEO_DIRECTORY=/mnt/${channelsHost}-${channelsPort}_ta/${video_directory}
CHANNELS_DIRECTORY=/mnt/${channelsHost}-${channelsPort}_ta/${channels_directory}
PROCESSED_FILES_TRACKER=/config/${channelsHost}-${channelsPort}_data/processed_files.txt
YOUTUBE_API_KEY=$youtube_api_key
APPRISE_URL=$apprise_url
CHANNELS_DVR_API_REFRESH_URL=http://$dvr/dvr/scanner/scan
DELETE_AFTER=$delete_after
EOF
}

scriptRun() {
  while true; do
    python3 -u /config/youtube-process.py >> $logFile 2>&1
    sleep $frequency
  done
}

main() {
  cd /config/"$channelsHost"-"$channelsPort"_data
  createConfig
  scriptRun
}

main
