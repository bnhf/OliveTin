#!/bin/bash

set -x

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
backgroundScript=$2
firstChar=${backgroundScript:0:1}
runInterval=$3
healthchecksIO=$4
[[ "$healthchecksIO" == "https://hc-ping.com/your_custom_uuid" ]] && healthchecksIO=""
runningScriptPID=$(ps -ef | grep "[$firstChar]${backgroundScript:1}.* $dvr" | awk '{print $2}')
[[ -n $runningScriptPID ]] && runningSleepPID=$(ps --ppid $runningScriptPID | grep sleep | awk '{print $1}')
backgroundArguments="$dvr $runInterval $healthchecksIO"
greenIcon=\"icons\/channels.png\"
purpleIcon=\"https:\/\/community-assets.getchannels.com\/original/2X/5/55232547f7e8f243069080b6aec0c71872f0f537.png\"
logFile=/config/"$channelsHost"-"$channelsPort"_"$backgroundScript"_latest.log

#Trap end of script run
finish() {
  echo -e "foreground.sh is exiting for $backgroundScript with exit code $?" >> "$logFile"
  cp /config/config.yaml /config/temp.yaml && cp /config/temp.yaml /config/config.yaml
  sleep 1
  [ -f $logFile ] && cat $logFile
}

trap finish EXIT

runningScripts() {
  servers=($CHANNELS_DVR $CHANNELS_DVR_ALTERNATES)

  for server in "${servers[@]}"; do
    serverHost=$(echo $server | awk -F: '{print $1}')
    serverPort=$(echo $server | awk -F: '{print $2}')
    activeProcess=$(ps -ef | grep "[$firstChar]${backgroundScript:1}.* $server" | awk '{print $2}')
    if [[ -n $activeProcess ]]; then
      echo "Background $backgroundScript process running for $server" >> $logFile
    fi
  done
}

scriptRun() {
case "$runInterval" in
  "once")
    /config/$backgroundScript.sh $dvr $runInterval \
    && echo "One time run mode used..." \
    && exit 0
  ;;
  
  "0")
    kill $runningScriptPID $runningSleepPID \
    && echo "Killing script/sleep with PIDs $runningScriptPID/$runningSleepPID for $dvr" > $logFile
    rm /config/"$channelsHost"-"$channelsPort"_"$backgroundScript".running
    sleep 2
    lastActive=$(ps -e | grep $backgroundScript | awk '{print $1}')

    if [[ -z $lastActive ]]; then
      sed -i "/#${backgroundScript} title/s/(.*) #/#/" /config/config.yaml
      sed -i "/#${backgroundScript} icon/s|img src = .* width|img src = $purpleIcon width|" /config/config.yaml
      sed -i "/#${backgroundScript} interval default/s/default: .* #/default: once #/" /config/config.yaml
      sed -i "/#${backgroundScript} healthchecks default/s/default: .* #/default: https:\/\/hc-ping.com\/your_custom_uuid #/" /config/config.yaml
      exit 0
    fi

    runningScripts
    exit 0
  ;;

  *)
    [[ -n $runningScriptPID ]] && kill $runningScriptPID $runningSleepPID \
    && echo "Killing currently running script/sleep with PIDs $runningScriptPID/$runningSleepPID" \
    && sed -i "/#${backgroundScript} title/s/(.*) #/($(date +'%d%b%y_%H:%M')) #/" /config/config.yaml \
    && sed -i "/#${backgroundScript} icon/s|img src = .* width|img src = $greenIcon width|" /config/config.yaml

    echo "Background script initiated, with $runInterval between runs for $dvr" > $logFile
    nohup /config/$backgroundScript.sh $backgroundArguments &>/dev/null &
    
    grep -q '(.*) #'"$backgroundScript"'' /config/config.yaml
    [[ "$?" == "1" ]] \
    && sed -i "/#${backgroundScript} title/s/#/($(date +'%d%b%y_%H:%M')) #/" /config/config.yaml \
    && sed -i "/#${backgroundScript} icon/s|img src = .* width|img src = $greenIcon width|" /config/config.yaml
            
    sed -i "/#${backgroundScript} interval default/s/default: .* #/default: ${runInterval} #/" /config/config.yaml
    [[ -n $healthchecksIO ]] && echo "Using healthcheck.io pings to $healthchecksIO to confirm functionality" >> $logFile \
    && sed -i "/#${backgroundScript} healthchecks default/s|default: .* #|default: ${healthchecksIO} #|" /config/config.yaml
    echo "$dvr $backgroundScript $runInterval $healthchecksIO" > /config/"$channelsHost"-"$channelsPort"_"$backgroundScript".running

    runningScripts
    exit 0
  ;;

esac
}

main() {
  scriptRun
}

main