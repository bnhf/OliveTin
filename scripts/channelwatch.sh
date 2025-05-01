#!/bin/bash
# channelwatch.sh
# 2025.04.03

set -x

dvr=$1
channelsHost=$(echo "$dvr" | awk -F: '{print $1}')
  if [[ $channelsHost =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    channelsIP="$channelsHost"
  else
    channelsIP=$(getent hosts $channelsHost | awk '{print $1}')
  fi

channelsPort=$(echo "$dvr" | awk -F: '{print $2}')
foregroundScript=channelwatch
runningScriptPID=$(ps -ef | grep "[d]ocker .* --name $channelsHost-$channelsPort" | awk '{print $2}')
greenIcon=\"icons\/channels.png\"
purpleIcon=\"https:\/\/community-assets.getchannels.com\/original/2X/5/55232547f7e8f243069080b6aec0c71872f0f537.png\"
logFile=/config/"$channelsHost"-"$channelsPort"_"$foregroundScript"_latest.log
  [[ -f $logFile && $PERSISTENT_LOGS != "true" ]] && rm $logFile
configFile=/config/config.yaml
configTemp=/tmp/config.yaml
channelwatchDNS="${45}"
channelwatchDNSArgument="--dns $channelwatchDNS"
olivetinSearch=$(grep search /etc/resolv.conf | head -n 1 | awk '{print $2}')
channelwatchVersion="0.5"

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

  if [[ -z $lastActive ]]; then
    sed -i "/#${foregroundScript} icon/s|img src = .* width|img src = $purpleIcon width|" $configTemp
    sed -i "/#${foregroundScript} title/s/(.*) #/#/" $configTemp
    sed -i "/#${foregroundScript} log_level default/s/default: .* #/default: 1 #/" $configTemp
    sed -i "/#${foregroundScript} log_retention_days default/s/default: .* #/default: 7 #/" $configTemp
    sed -i "/#${foregroundScript} channel_watching default/s/default: .* #/default: \"true\" #/" $configTemp
    sed -i "/#${foregroundScript} vod_watching default/s/default: .* #/default: \"true\" #/" $configTemp
    sed -i "/#${foregroundScript} disk_space default/s/default: .* #/default: \"true\" #/" $configTemp
    sed -i "/#${foregroundScript} stream_count default/s/default: .* #/default: \"true\" #/" $configTemp
    sed -i "/#${foregroundScript} rd_alert_scheduled default/s/default: .* #/default: \"true\" #/" $configTemp
    sed -i "/#${foregroundScript} rd_alert_started default/s/default: .* #/default: \"true\" #/" $configTemp
    sed -i "/#${foregroundScript} rd_alert_completed default/s/default: .* #/default: \"true\" #/" $configTemp
    sed -i "/#${foregroundScript} rd_alert_cancelled default/s/default: .* #/default: \"true\" #/" $configTemp
    sed -i "/#${foregroundScript} channel_name default/s/default: .* #/default: \"true\" #/" $configTemp
    sed -i "/#${foregroundScript} channel_number default/s/default: .* #/default: \"true\" #/" $configTemp
    sed -i "/#${foregroundScript} program_name default/s/default: .* #/default: \"true\" #/" $configTemp
    sed -i "/#${foregroundScript} device_name default/s/default: .* #/default: \"true\" #/" $configTemp
    sed -i "/#${foregroundScript} device_ip_address default/s/default: .* #/default: \"true\" #/" $configTemp
    sed -i "/#${foregroundScript} stream_source default/s/default: .* #/default: \"true\" #/" $configTemp
    sed -i "/#${foregroundScript} image_source default/s/default: .* #/default: PROGRAM #/" $configTemp
    sed -i "/#${foregroundScript} vod_title default/s/default: .* #/default: \"true\" #/" $configTemp
    sed -i "/#${foregroundScript} vod_episode_title default/s/default: .* #/default: \"true\" #/" $configTemp
    sed -i "/#${foregroundScript} vod_summary default/s/default: .* #/default: \"true\" #/" $configTemp
    sed -i "/#${foregroundScript} vod_duration default/s/default: .* #/default: \"true\" #/" $configTemp
    sed -i "/#${foregroundScript} vod_progress default/s/default: .* #/default: \"true\" #/" $configTemp
    sed -i "/#${foregroundScript} vod_image default/s/default: .* #/default: \"true\" #/" $configTemp
    sed -i "/#${foregroundScript} vod_rating default/s/default: .* #/default: \"true\" #/" $configTemp
    sed -i "/#${foregroundScript} vod_genres default/s/default: .* #/default: \"true\" #/" $configTemp
    sed -i "/#${foregroundScript} vod_cast default/s/default: .* #/default: \"true\" #/" $configTemp
    sed -i "/#${foregroundScript} vod_device_name default/s/default: .* #/default: \"true\" #/" $configTemp
    sed -i "/#${foregroundScript} vod_device_ip default/s/default: .* #/default: \"true\" #/" $configTemp
    sed -i "/#${foregroundScript} ds_threshold_percent default/s/default: .* #/default: 10 #/" $configTemp
    sed -i "/#${foregroundScript} ds_threshold_gb default/s/default: .* #/default: 50 #/" $configTemp
    sed -i "/#${foregroundScript} channel_cache_ttl default/s/default: .* #/default: 86400 #/" $configTemp
    sed -i "/#${foregroundScript} program_cache_ttl default/s/default: .* #/default: 86400 #/" $configTemp
    sed -i "/#${foregroundScript} vod_cache_ttl default/s/default: .* #/default: 86400 #/" $configTemp
    sed -i "/#${foregroundScript} job_cache_ttl default/s/default: .* #/default: 3600 #/" $configTemp
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
  && optionalArguments="-e CHANNELS_DVR_HOST=$channelsIP -e CHANNELS_DVR_PORT=$channelsPort -e TZ=$TZ -e LOG_LEVEL=$logLevel" \
  && sed -i "/#${foregroundScript} log_level default/s/default: .* #/default: ${logLevel} #/" $configTemp
logRetentionDays=$3
  [[ "$logRetentionDays" != "7" ]] && optionalArguments="$optionalArguments -e LOG_RETENTION_DAYS=$logRetentionDays" \
  && sed -i "/#${foregroundScript} log_retention_days default/s/default: .* #/default: ${logRetentionDays} #/" $configTemp
channelWatching=$4
  [[ "$channelWatching" != "TRUE" ]] && optionalArguments="$optionalArguments -e Alerts_Channel-Watching=$channelWatching" \
  && sed -i "/#${foregroundScript} channel_watching default/s/default: .* #/default: \"${channelWatching}\" #/" $configTemp
vodWatching=$5
  [[ "$vodWatching" != "TRUE" ]] && optionalArguments="$optionalArguments -e Alerts_VOD-Watching=$vodWatching" \
  && sed -i "/#${foregroundScript} vod_watching default/s/default: .* #/default: \"${vodWatching}\" #/" $configTemp
diskSpace=$6
  [[ "$diskSpace" != "TRUE" ]] && optionalArguments="$optionalArguments -e Alerts_Disk-Space=$diskSpace" \
  && sed -i "/#${foregroundScript} disk_space default/s/default: .* #/default: \"${diskSpace}\" #/" $configTemp
recordingEvents=$7
  [[ "$recordingEvents" != "TRUE" ]] && optionalArguments="$optionalArguments -e Alerts_Recording-Events=$recordingEvents" \
  && sed -i "/#${foregroundScript} recording_events default/s/default: .* #/default: \"${recordingEvents}\" #/" $configTemp
streamCount=$8
  [[ "$streamCount" != "TRUE" ]] && optionalArguments="$optionalArguments -e STREAM_COUNT=$streamCount" \
  && sed -i "/#${foregroundScript} stream_count default/s/default: .* #/default: \"${streamCount}\" #/" $configTemp
alertScheduled=$9
  [[ "$alertScheduled" != "TRUE" ]] && optionalArguments="$optionalArguments -e RD_ALERT_SCHEDULED=$alertScheduled" \
  && sed -i "/#${foregroundScript} rd_alert_scheduled default/s/default: .* #/default: \"${alertScheduled}\" #/" $configTemp
alertStarted=${10}
  [[ "$alertStarted" != "TRUE" ]] && optionalArguments="$optionalArguments -e RD_ALERT_STARTED=$alertStarted" \
  && sed -i "/#${foregroundScript} rd_alert_started default/s/default: .* #/default: \"${alertStarted}\" #/" $configTemp
alertCompleted=${11}
  [[ "$alertCompleted" != "TRUE" ]] && optionalArguments="$optionalArguments -e RD_ALERT_COMPLETED=$alertCompleted" \
  && sed -i "/#${foregroundScript} rd_alert_completed default/s/default: .* #/default: \"${alertCompleted}\" #/" $configTemp
alertCancelled=${12}
  [[ "$alertCancelled" != "TRUE" ]] && optionalArguments="$optionalArguments -e RD_ALERT_CANCELLED=$alertCancelled" \
  && sed -i "/#${foregroundScript} rd_alert_cancelled default/s/default: .* #/default: \"${alertCancelled}\" #/" $configTemp
channelName=${13}
  [[ "$channelName" != "TRUE" ]] && optionalArguments="$optionalArguments -e CHANNEL_NAME=$channelName" \
  && sed -i "/#${foregroundScript} channel_name default/s/default: .* #/default: \"${channelName}\" #/" $configTemp
channelNumber=${14}
  [[ "$channelNumber" != "TRUE" ]] && optionalArguments="$optionalArguments -e CHANNEL_NUMBER=$channelNumber" \
  && sed -i "/#${foregroundScript} channel_number default/s/default: .* #/default: \"${channelNumber}\" #/" $configTemp
programName=${15}
  [[ "$programName" != "TRUE" ]] && optionalArguments="$optionalArguments -e PROGRAM_NAME=$programName" \
  && sed -i "/#${foregroundScript} program_name default/s/default: .* #/default: \"${programName}\" #/" $configTemp
deviceName=${16}
  [[ "$deviceName" != "TRUE" ]] && optionalArguments="$optionalArguments -e DEVICE_NAME=$deviceName" \
  && sed -i "/#${foregroundScript} device_name default/s/default: .* #/default: \"${deviceName}\" #/" $configTemp
deviceIPAddress=${17}
  [[ "$deviceIPAddress" != "TRUE" ]] && optionalArguments="$optionalArguments -e DEVICE_IP_ADDRESS=$deviceIPAddress" \
  && sed -i "/#${foregroundScript} device_ip_address default/s/default: .* #/default: \"${deviceIPAddress}\" #/" $configTemp
streamSource=${18}
  [[ "$streamSource" != "TRUE" ]] && optionalArguments="$optionalArguments -e STREAM_SOURCE=$streamSource" \
  && sed -i "/#${foregroundScript} stream_source default/s/default: .* #/default: \"${streamSource}\" #/" $configTemp
imageSource=${19}
  [[ "$imageSource" != "PROGRAM" ]] && optionalArguments="$optionalArguments -e IMAGE_SOURCE=$imageSource" \
  && sed -i "/#${foregroundScript} image_source default/s/default: .* #/default: \"${imageSource}\" #/" $configTemp
vodTitle=${20}
  [[ "$vodTitle" != "TRUE" ]] && optionalArguments="$optionalArguments -e VOD_TITLE=$vodTitle" \
  && sed -i "/#${foregroundScript} vod_title default/s/default: .* #/default: \"${vodTitle}\" #/" $configTemp
vodEpisodeTitle=${21}
  [[ "$vodEpisodeTitle" != "TRUE" ]] && optionalArguments="$optionalArguments -e VOD_EPISODE_TITLE=$vodEpisodeTitle" \
  && sed -i "/#${foregroundScript} vod_episode_title default/s/default: .* #/default: \"${vodEpisodeTitle}\" #/" $configTemp
vodSummary=${22}
  [[ "$vodSummary" != "TRUE" ]] && optionalArguments="$optionalArguments -e VOD_SUMMARY=$vodSummary" \
  && sed -i "/#${foregroundScript} vod_summary default/s/default: .* #/default: \"${vodSummary}\" #/" $configTemp
vodDuration=${23}
  [[ "$vodDuration" != "TRUE" ]] && optionalArguments="$optionalArguments -e VOD_DURATION=$vodDuration" \
  && sed -i "/#${foregroundScript} vod_duration default/s/default: .* #/default: \"${vodDuration}\" #/" $configTemp
vodProgress=${24}
  [[ "$vodProgress" != "TRUE" ]] && optionalArguments="$optionalArguments -e VOD_PROGRESS=$vodProgress" \
  && sed -i "/#${foregroundScript} vod_progress default/s/default: .* #/default: \"${vodProgress}\" #/" $configTemp
vodImage=${25}
  [[ "$vodImage" != "TRUE" ]] && optionalArguments="$optionalArguments -e VOD_IMAGE=$vodImage" \
  && sed -i "/#${foregroundScript} vod_image default/s/default: .* #/default: \"${vodImage}\" #/" $configTemp 
vodRating=${26}
  [[ "$vodRating" != "TRUE" ]] && optionalArguments="$optionalArguments -e VOD_RATING=$vodRating" \
  && sed -i "/#${foregroundScript} vod_rating default/s/default: .* #/default: \"${vodRating}\" #/" $configTemp 
vodGenres=${27}
  [[ "$vodGenres" != "TRUE" ]] && optionalArguments="$optionalArguments -e VOD_GENRES=$vodGenres" \
  && sed -i "/#${foregroundScript} vod_genres default/s/default: .* #/default: \"${vodGenres}\" #/" $configTemp 
vodCast=${28}
  [[ "$vodCast" != "TRUE" ]] && optionalArguments="$optionalArguments -e VOD_CAST=$vodCast" \
  && sed -i "/#${foregroundScript} vod_cast default/s/default: .* #/default: \"${vodCast}\" #/" $configTemp
vodDeviceName=${29}
  [[ "$vodDeviceName" != "TRUE" ]] && optionalArguments="$optionalArguments -e VOD_DEVICE_NAME=$vodDeviceName" \
  && sed -i "/#${foregroundScript} vod_device_name default/s/default: .* #/default: \"${vodDeviceName}\" #/" $configTemp 
vodDeviceIP=${30}
  [[ "$vodDeviceIP" != "TRUE" ]] && optionalArguments="$optionalArguments -e VOD_DEVICE_IP=$vodDeviceIP" \
  && sed -i "/#${foregroundScript} vod_device_ip default/s/default: .* #/default: \"${vodDeviceIP}\" #/" $configTemp
dsThresholdPercent=${31}
  [[ "$dsThresholdPercent" != "10" ]] && optionalArguments="$optionalArguments -e DS_THRESHOLD_PERCENT=$dsThresholdPercent" \
  && sed -i "/#${foregroundScript} ds_threshold_percent default/s/default: .* #/default: \"${dsThresholdPercent}\" #/" $configTemp
dsThresholdGB=${32}
  [[ "$dsThresholdGB" != "50" ]] && optionalArguments="$optionalArguments -e DS_THRESHOLD_GB=$dsThresholdGB" \
  && sed -i "/#${foregroundScript} ds_threshold_gb default/s/default: .* #/default: \"${dsThresholdGB}\" #/" $configTemp
channelCacheTTL=${33}
  [[ "$channelCacheTTL" != "50" ]] && optionalArguments="$optionalArguments -e CHANNEL_CACHE_TTL=$channelCacheTTL" \
  && sed -i "/#${foregroundScript} channel_cache_ttl default/s/default: .* #/default: \"${channelCacheTTL}\" #/" $configTemp
programCacheTTL=${34}
  [[ "$programCacheTTL" != "50" ]] && optionalArguments="$optionalArguments -e PROGRAM_CACHE_TTL=$programCacheTTL" \
  && sed -i "/#${foregroundScript} program_cache_ttl default/s/default: .* #/default: \"${programCacheTTL}\" #/" $configTemp
vodCacheTTL=${35}
  [[ "$vodCacheTTL" != "50" ]] && optionalArguments="$optionalArguments -e VOD_CACHE_TTL=$vodCacheTTL" \
  && sed -i "/#${foregroundScript} vod_cache_ttl default/s/default: .* #/default: \"${vodCacheTTL}\" #/" $configTemp
jobCacheTTL=${36}
  [[ "$jobCacheTTL" != "50" ]] && optionalArguments="$optionalArguments -e JOB_CACHE_TTL=$jobCacheTTL" \
  && sed -i "/#${foregroundScript} job_cache_ttl default/s/default: .* #/default: \"${jobCacheTTL}\" #/" $configTemp
pushoverUser=${37}
  [[ "$pushoverUser" != "none" ]] && optionalArguments="$optionalArguments -e PUSHOVER_USER_KEY=$pushoverUser" \
  && sed -i "/#${foregroundScript} pushover_user_key default/s/default: .* #/default: ${pushoverUser} #/" $configTemp
pushoverAPI=${38}
  [[ "$pushoverAPI" != "none" ]] && optionalArguments="$optionalArguments -e PUSHOVER_API_TOKEN=$pushoverAPI" \
  && sed -i "/#${foregroundScript} pushover_api_token default/s/default: .* #/default: ${pushoverAPI} #/" $configTemp
appriseDiscord=${39}
  [[ "$appriseDiscord" != "none" ]] && optionalArguments="$optionalArguments -e APPRISE_DISCORD=$appriseDiscord" \
  && sed -i "/#${foregroundScript} apprise_discord default/s/default: .* #/default: ${appriseDiscord} #/" $configTemp
appriseEmail=${40}
  [[ "$appriseEmail" != "none" ]] && optionalArguments="$optionalArguments -e APPRISE_EMAIL=$appriseEmail" \
  && sed -i "/#${foregroundScript} apprise_email default/s/default: .* #/default: ${appriseEmail} #/" $configTemp
appriseEmailTo=${41}
  [[ "$appriseEmailTo" != "none" ]] && optionalArguments="$optionalArguments -e APPRISE_EMAIL_TO=$appriseEmailTo" \
  && sed -i "/#${foregroundScript} apprise_email_to default/s/default: .* #/default: ${appriseEmailTo} #/" $configTemp
appriseTelegram=${42}
  [[ "$appriseTelegram" != "none" ]] && optionalArguments="$optionalArguments -e APPRISE_TELEGRAM=$appriseTelegram" \
  && sed -i "/#${foregroundScript} apprise_telegram default/s/default: .* #/default: ${appriseTelegram} #/" $configTemp
appriseSlack=${43}
  [[ "$appriseSlack" != "none" ]] && optionalArguments="$optionalArguments -e APPRISE_SLACK=$appriseSlack" \
  && sed -i "/#${foregroundScript} apprise_slack default/s/default: .* #/default: ${appriseSlack} #/" $configTemp
appriseCustom=${44}
  [[ "$appriseCustom" != "none" ]] && optionalArguments="$optionalArguments -e APPRISE_CUSTOM=$appriseCustom" \
  && sed -i "/#${foregroundScript} apprise_custom default/s/default: .* #/default: ${appriseCustom} #/" $configTemp

[ "$(echo "$pushoverUser $pushoverAPI $appriseDiscord $appriseEmail $appriseEmailTo $appriseTelegram $appriseSlack $appriseCustom" | tr ' ' '\n' | grep -vc '^none$')" -eq 0 ] \
  && echo "You must configure at least one notification method" \
  && exit 0

scriptRun() {
  runningScriptPID=$(ps -ef | grep "[d]ocker .* --name $containerName" | awk '{print $2}')
  [[ -n $runningScriptPID ]] && kill $runningScriptPID && echo "Killing currently running script with PID $runningScriptPID" \
  && sed -i "/#${foregroundScript} title/s/(.*) #/($(date +'%d%b%y_%H:%M')) #/" $configTemp \
  && sed -i "/#${foregroundScript} icon/s|img src = .* width|img src = $greenIcon width|" $configTemp
  [[ "$(docker inspect --format='{{ index .Config.Labels "version" }}' coderluii/channelwatch:latest)" != "$channelwatchVersion" ]] && docker pull coderluii/channelwatch:latest
  nohup docker run --name $containerName $channelwatchDNSArgument --dns-search $olivetinSearch $optionalArguments -v $containerName:/config --restart unless-stopped coderluii/channelwatch:latest >> $logFile 2>&1 &
  runningScriptPID=$!
  echo "$foregroundScript.sh $dvr $logLevel $logRetentionDays $channelWatching $vodWatching $diskSpace $recordingEvents $streamCount $alertScheduled $alertStarted $alertCompleted $alertCancelled $channelName $channelNumber $programName $deviceName $deviceIPAddress $streamSource $imageSource $vodTitle $vodEpisodeTitle $vodSummary $vodDuration $vodProgress $vodImage $vodRating $vodGenres $vodCast $vodDeviceName $vodDeviceIP $dsThresholdPercent $dsThresholdGB $channelCacheTTL $programCacheTTL $vodCacheTTL $jobCacheTTL $pushoverUser $pushoverAPI $appriseDiscord $appriseEmail $appriseEmailTo $appriseTelegram $appriseSlack $appriseCustom '$channelwatchDNS'" > /config/"$channelsHost"-"$channelsPort"_channelwatch.running

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
