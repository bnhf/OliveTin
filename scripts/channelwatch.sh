#!/bin/bash
# channelwatch.sh
# 2025.03.24

set -x

dvr=$1
channelsHost=$(echo "$dvr" | awk -F: '{print $1}')
channelsPort=$(echo "$dvr" | awk -F: '{print $2}')
channelsIP=$(getent hosts $channelsHost | awk '{print $1}')
foregroundScript=channelwatch
runningScriptPID=$(ps -ef | grep "[d]ocker .* --name $channelsHost-$channelsPort" | awk '{print $2}')
greenIcon=\"icons\/channels.png\"
purpleIcon=\"https:\/\/community-assets.getchannels.com\/original/2X/5/55232547f7e8f243069080b6aec0c71872f0f537.png\"
logFile=/config/"$channelsHost"-"$channelsPort"_"$foregroundScript"_latest.log
  [[ -f $logFile && $PERSISTENT_LOGS != "true" ]] && rm $logFile
configFile=/config/config.yaml
configTemp=/tmp/config.yaml

#Trap end of script run
finish() {
  cp $configTemp /config
}

trap finish EXIT

assignContainerNames() {
  servers=($CHANNELS_DVR $CHANNELS_DVR_ALTERNATES)

  serverNumber=1
  for server in "${servers[@]}"; do
    currentContainer="channelwatch${serverNumber}"
    containerList=$(echo "${containerList}${currentContainer} ")
    [[ "$server" == "$dvr" ]] && containerName="$currentContainer"
    ((serverNumber++))
  done

  IFS=' ' read -r -a containers <<< "$containerList"
}

runningScripts() {
  servers=($CHANNELS_DVR $CHANNELS_DVR_ALTERNATES)
  for server in "${servers[@]}"; do
    serverHost=$(echo $server | awk -F: '{print $1}')
    serverPort=$(echo $server | awk -F: '{print $2}')
    activeProcess=$(ps -ef | grep "[d]ocker .* --label $channelsHost-$ChannelsPort" | awk '{print $2}')
    if [[ -n $activeProcess ]]; then
      echo "Background ChannelWatch Notifications process running for $server"
    fi
  done
}

scriptKill() {
  runningScriptPID=$(ps -ef | grep "[d]ocker .* --name $containerName" | awk '{print $2}')
  kill $runningScriptPID
  rm /config/"$channelsHost"-"$channelsPort"_channelwatch.running
  echo "Killing ChannelWatch Notifications PID $runningScriptPID"
  sleep 2
  docker rm $containerName
  echo "Removing Docker container $containerName"
  sleep 2
  lastActive=$(ps -e | grep "docker .* --name channelwatch" | awk '{print $1}')

# "{{ dvr }}" "{{ log_level }}" "{{ log_retention_days }}" "{{ alerts_channel_watching }}" "{{ channel_images }}" "{{ pushover_user_key }}" "{{ pushover_api_token }}" "{{ apprise_discord }}" "{{ apprise_email }}" "{{ apprise_email_to }}" "{{ apprise_telegram }}" "{{ apprise_slack }}" "{{ apprise_custom }}"

  if [[ -z $lastActive ]]; then
    sed -i "/#${foregroundScript} icon/s|img src = .* width|img src = $purpleIcon width|" $configTemp
    sed -i "/#${foregroundScript} title/s/(.*) #/#/" $configTemp
    sed -i "/#${foregroundScript} log_level default/s/default: .* #/default: 1 #/" $configTemp
    sed -i "/#${foregroundScript} log_retention_days default/s/default: .* #/default: 7 #/" $configTemp
    sed -i "/#${foregroundScript} alerts_channel_watching default/s/default: .* #/default: \"true\" #/" $configTemp
    sed -i "/#${foregroundScript} channel_images default/s/default: .* #/default: \"true\" #/" $configTemp
    sed -i "/#${foregroundScript} pushover_user_key default/s/default: .* #/default: none #/" $configTemp
    sed -i "/#${foregroundScript} pushover_api_token default/s/default: .* #/default: none #/" $configTemp
    sed -i "/#${foregroundScript} apprise_discord default/s/default: .* #/default: none #/" $configTemp
    sed -i "/#${foregroundScript} apprise_email default/s/default: .* #/default: none #/" $configTemp
    sed -i "/#${foregroundScript} apprise_email_to default/s/default: .* #/default: none #/" $configTemp
    sed -i "/#${foregroundScript} apprise_telegram default/s/default: .* #/default: none #/" $configTemp
    sed -i "/#${foregroundScript} apprise_slack default/s/default: .* #/default: none #/" $configTemp
    sed -i "/#${foregroundScript} apprise_custom default/s/default: .* #/default: none #/" $configTemp
    exit 0
  fi

  runningScripts
  exit 0
}

cp $configFile /tmp
logLevel=$2
  [[ "$logLevel" == "0" ]] && assignContainerNames && scriptKill
  [[ "$logLevel" != "0" ]] && assignContainerNames \
  && optionalArguments="-e CHANNELS_DVR_HOST=$channelsIP -e CHANNELS_DVR_PORT=$channelsPort -e LOG_LEVEL=$logLevel" \
  && sed -i "/#${foregroundScript} log_level default/s/default: .* #/default: ${logLevel} #/" $configTemp
logRetentionDays=$3
  [[ "$logRetentionDays" != "7" ]] && optionalArguments="$optionalArguments -e LOG_RETENTION_DAYS=$logRetentionDays" \
  && sed -i "/#${foregroundScript} log_retention_days default/s/default: .* #/default: ${logRetentionDays} #/" $configTemp
alertsChannelWatching=$4
  [[ "$alertsChannelWatching" != "TRUE" ]] && optionalArguments="$optionalArguments -e Alerts_Channel-Watching=$alertsChannelWatching" \
  && sed -i "/#${foregroundScript} alerts_channel_watching default/s/default: .* #/default: \"${alertsChannelWatching}\" #/" $configTemp
channelImages=$5
  [[ "$alertsChannelWatching" != "TRUE" ]] && optionalArguments="$optionalArguments -e CHANNEL_IMAGES=$channelImages" \
  && sed -i "/#${foregroundScript} channel_images default/s/default: .* #/default: \"${channelImages}\" #/" $configTemp
pushoverUser=$6
  [[ "$pushoverUser" != "none" ]] && optionalArguments="$optionalArguments -e PUSHOVER_USER_KEY=$pushoverUser" \
  && sed -i "/#${foregroundScript} pushover_user_key default/s/default: .* #/default: ${pushoverUser} #/" $configTemp
pushoverAPI=$7
  [[ "$pushoverAPI" != "none" ]] && optionalArguments="$optionalArguments -e PUSHOVER_API_TOKEN=$pushoverAPI" \
  && sed -i "/#${foregroundScript} pushover_api_token default/s/default: .* #/default: ${pushoverAPI} #/" $configTemp
appriseDiscord=$8
  [[ "$appriseDiscord" != "none" ]] && optionalArguments="$optionalArguments -e APPRISE_DISCORD=$appriseDiscord" \
  && sed -i "/#${foregroundScript} apprise_discord default/s/default: .* #/default: ${appriseDiscord} #/" $configTemp
appriseEmail=$9
  [[ "$appriseEmail" != "none" ]] && optionalArguments="$optionalArguments -e APPRISE_EMAIL=$appriseEmail" \
  && sed -i "/#${foregroundScript} apprise_email default/s/default: .* #/default: ${appriseEmail} #/" $configTemp
appriseEmailTo=${10}
  [[ "$appriseEmailTo" != "none" ]] && optionalArguments="$optionalArguments -e APPRISE_EMAIL_TO=$appriseEmailTo" \
  && sed -i "/#${foregroundScript} apprise_email_to default/s/default: .* #/default: ${appriseEmailTo} #/" $configTemp
appriseTelegram=${11}
  [[ "$appriseTelegram" != "none" ]] && optionalArguments="$optionalArguments -e APPRISE_TELEGRAM=$appriseTelegram" \
  && sed -i "/#${foregroundScript} apprise_telegram default/s/default: .* #/default: ${appriseTelegram} #/" $configTemp
appriseSlack=${12}
  [[ "$appriseSlack" != "none" ]] && optionalArguments="$optionalArguments -e APPRISE_SLACK=$appriseSlack" \
  && sed -i "/#${foregroundScript} apprise_slack default/s/default: .* #/default: ${appriseSlack} #/" $configTemp
appriseCustom=${13}
  [[ "$appriseCustom" != "none" ]] && optionalArguments="$optionalArguments -e APPRISE_CUSTOM=$appriseCustom" \
  && sed -i "/#${foregroundScript} apprise_custom default/s/default: .* #/default: ${appriseCustom} #/" $configTemp

scriptRun() {
  runningScriptPID=$(ps -ef | grep "[d]ocker .* --name $containerName" | awk '{print $2}')
  [[ -n $runningScriptPID ]] && kill $runningScriptPID && echo "Killing currently running script with PID $runningScriptPID" \
  && sed -i "/#${foregroundScript} title/s/(.*) #/($(date +'%d%b%y_%H:%M')) #/" $configTemp \
  && sed -i "/#${foregroundScript} icon/s|img src = .* width|img src = $greenIcon width|" $configTemp
  #nohup env LOG_LEVEL=$logLevel Alerts_Channel-Watching=$alertsChannelWatching CHANNELWATCH_PATH=$channelWatchPath PUSHOVER_USER_KEY=$pushoverUser PUSHOVER_API_TOKEN=$pushoverAPI python3 -m $foregroundScript.main --instance $channelsHost-$channelsPort >> $logFile 2>&1 &
  nohup docker run --label $CHANNELS_DVR_HOST-$CHANNELS_DVR_PORT --name $containerName $optionalArguments coderluii/channelwatch:latest >> $logFile 2>&1 &
  runningScriptPID=$!
  echo "$foregroundScript.sh $dvr $logLevel $logRetentionDays $alertsChannelWatching $channelImages $pushoverUser $pushoverAPI $appriseDiscord $appriseEmail $appriseEmailTo $appriseTelegram $appriseSlack $appriseCustom" > /config/"$channelsHost"-"$channelsPort"_channelwatch.running

  grep -q '(.*) #'"$foregroundScript"'' $configTemp
    [[ "$?" == "1" ]] \
    && sed -i "/#${foregroundScript} title/s/#/($(date +'%d%b%y_%H:%M')) #/" $configTemp \
    && sed -i "/#${foregroundScript} icon/s|img src = .* width|img src = $greenIcon width|" $configTemp

  sleep 2
  cat $logFile

  runningScripts
}

main() {
  scriptRun
}

main
