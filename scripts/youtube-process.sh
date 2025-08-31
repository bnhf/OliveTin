#!/bin/bash
# youtube-process.sh
# 2025.05.05

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x

dvr=$1
channelsHost=$(echo "$dvr" | awk -F: '{print $1}')
channelsPort=$(echo "$dvr" | awk -F: '{print $2}')
foregroundScript=youtube-process
backgroundScript=youtube-processor
firstChar=${backgroundScript:0:1}
runningScriptPID=$(ps -ef | grep "[$firstChar]${backgroundScript:1}.* $dvr" | awk '{print $2}')
[[ -n $runningScriptPID ]] && runningSleepPID=$(ps --ppid $runningScriptPID | grep sleep | awk '{print $1}')
greenIcon=\"icons\/channels.png\"
#greenIcon=\"custom-webui\/icons\/channels.png\"
purpleIcon=\"https:\/\/community-assets.getchannels.com\/original/2X/5/55232547f7e8f243069080b6aec0c71872f0f537.png\"
logFile=/config/"$channelsHost"-"$channelsPort"_"$backgroundScript"_latest.log
  [[ -f $logFile ]] && rm $logFile
configFile=/config/config.yaml
configTemp=/tmp/config.yaml
configTubeArchivist=/config/config.txt

#Trap end of script run
finish() {
  #nohup /config/finish.sh $configTemp >> $logFile 2>&1 &
  cp $configTemp /config
}

trap finish EXIT

runningScripts() {
  servers=($CHANNELS_DVR $CHANNELS_DVR_ALTERNATES)

  for server in "${servers[@]}"; do
    serverHost=$(echo $server | awk -F: '{print $1}')
    serverPort=$(echo $server | awk -F: '{print $2}')
    activeProcess=$(ps -ef | grep "[$firstChar]${backgroundScript:1}.* $server" | awk '{print $2}')
    if [[ -n $activeProcess ]]; then
      echo "Background Tube Archivist processor running for $server"
    fi
  done
}

scriptKill() {
  runningScriptPID=$(ps -ef | grep "[$firstChar]${backgroundScript:1}.* $dvr" | awk '{print $2}')
  [[ -n $runningScriptPID ]] && runningSleepPID=$(ps --ppid $runningScriptPID | grep sleep | awk '{print $1}')
  kill $runningScriptPID $runningSleepPID > $logFile \
    && echo "Killing script/sleep with PIDs $runningScriptPID/$runningSleepPID for $dvr" >> $logFile
  rm /config/"$channelsHost"-"$channelsPort"_youtube-process.running
  echo "Killing Tube Archivist Handler PID $runningScriptPID"
  sleep 2
  lastActive=$(ps -e | grep "[$firstChar]${backgroundScript:1}.* $dvr" | awk '{print $1}')

  if [[ -z $lastActive ]]; then
    sed -i "/#${foregroundScript} icon/s|img src = .* width|img src = $purpleIcon width|" $configTemp
    sed -i "/#${foregroundScript} title/s/(.*) #/#/" $configTemp
    sed -i "/#${foregroundScript} frequency default/s/default: .* #/default: 12h #/" $configTemp
    sed -i "/#${foregroundScript} youtube_api_key default/s/default: .* #/default: none #/" $configTemp
    sed -i "/#${foregroundScript} apprise_url default/s/default: .* #/default: none #/" $configTemp
    sed -i "/#${foregroundScript} delete_after default/s/default: .* #/default: none #/" $configTemp
    sed -i "/#${foregroundScript} video_directory default/s/default: .* #/default: tubearchivist #/" $configTemp
    sed -i "/#${foregroundScript} channels_directory default/s/default: .* #/default: Imports/Videos #/" $configTemp    
    exit 0
  fi

  runningScripts
  exit 0
}

cp $configFile /tmp
frequency=$2
  [[ "$frequency" == "0" ]] && scriptKill
  [[ "$frequency" != "0" ]] \
  && sed -i "/#${foregroundScript} frequency default/s/default: .* #/default: ${frequency} #/" $configTemp
youtube_api_key=$3
  [[ "$youtube_api_key" != "none" ]] \
  && sed -i "/#${foregroundScript} youtube_api_key default/s/default: .* #/default: ${youtube_api_key} #/" $configTemp
apprise_url=$4
  [[ "$apprise_url" != "none" ]] \
  && sed -i "/#${foregroundScript} apprise_url default/s|default: .* #|default: ${apprise_url} #|" $configTemp
delete_after=$5
  [[ "$delete_after" != "none" ]] \
  && sed -i "/#${foregroundScript} delete_after default/s/default: .* #/default: ${delete_after} #/" $configTemp
video_directory=$6
  [[ "$video_directory" != "tubearchivist" ]] \
  && sed -i "/#${foregroundScript} video_directory default/s/default: .* #/default: ${video_directory} #/" $configTemp
channels_directory=$7
  [[ "$channels_directory" != "Imports/Videos" ]] \
  && sed -i "/#${foregroundScript} channels_directory default/s/default: .* #/default: ${channels_directory} #/" $configTemp
backgroundArguments="$dvr $frequency $youtube_api_key $apprise_url $delete_after $video_directory $channels_directory"

scriptRun() {
  runningScriptPID=$(ps -ef | grep "[$firstChar]${backgroundScript:1}.* $dvr" | awk '{print $2}')
  [[ -n $runningScriptPID ]] && kill $runningScriptPID && echo "Killing currently running script with PID $runningScriptPID" \
  && sed -i "/#${foregroundScript} title/s/(.*) #/($(date +'%d%b%y_%H:%M')) #/" $configTemp \
  && sed -i "/#${foregroundScript} icon/s|img src = .* width|img src = $greenIcon width|" $configTemp
  nohup /config/$backgroundScript.sh $backgroundArguments &>/dev/null &
  runningScriptPID=$!
  echo "$foregroundScript.sh $backgroundArguments" > /config/"$channelsHost"-"$channelsPort"_youtube-process.running

  grep -q '(.*) #'"$foregroundScript"'' $configTemp
    [[ "$?" == "1" ]] \
    && sed -i "/#${foregroundScript} title/s/#/($(date +'%d%b%y_%H:%M')) #/" $configTemp \
    && sed -i "/#${foregroundScript} icon/s|img src = .* width|img src = $greenIcon width|" $configTemp

  sleep 2
  cat $logFile

  runningScripts
}

main() {
  #cd /config
  #createConfig
  scriptRun
}

main
