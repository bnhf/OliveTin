#!/bin/bash
# foreground.sh
# 2026.02.11

script=$2
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
backgroundScript=$2
firstChar=${backgroundScript:0:1}
runInterval=$3
healthchecksIO=$4
foregroundArguments="$dvr $backgroundScript $runInterval $healthchecksIO"
[[ "$healthchecksIO" == "https://hc-ping.com/your_custom_uuid" ]] && healthchecksIO=""
spinUp=$5
runningScriptPID=$(ps -ef | grep "[$firstChar]${backgroundScript:1}.* $dvr" | awk '{print $2}')
[[ -n $runningScriptPID ]] && runningSleepPID=$(ps --ppid $runningScriptPID | grep sleep | awk '{print $1}')
backgroundArguments="$dvr $runInterval $healthchecksIO"
#greenIcon=\"icons\/channels.png\"
greenIcon=\"custom-webui\/icons\/channels.png\"
purpleIcon=\"https:\/\/community-assets.getchannels.com\/original/2X/5/55232547f7e8f243069080b6aec0c71872f0f537.png\"
logFile=/config/"$channelsHost"-"$channelsPort"_"$backgroundScript"_latest.log
logTemp=/tmp/"$channelsHost"-"$channelsPort"_"$backgroundScript"_foreground.log
  [[ -f $logTemp ]] && rm $logTemp
runFile=/tmp/"$channelsHost"-"$channelsPort"_"$backgroundScript".run
  [[ -f $runFile ]] && rm $runFile
  [[ $spinUp ]] && touch $runFile
configFile=/config/config.yaml
configTemp=/tmp/config.yaml
greenEcho() { echo -e "\033[0;32m$1\033[0m ${*:2}"; }

finish() {
  echo -e "\nforeground.sh is exiting for $backgroundScript with exit code $?" >> "$logTemp"
  [ -f $logTemp ] && sed 's/\x1b\[[0-9;]*m//g' $logTemp >> "$logFile"
  cp $configTemp /config
  [ -f $logTemp ] && cat $logTemp
}

trap finish EXIT

runningScripts() {
  servers=($CHANNELS_DVR $CHANNELS_DVR_ALTERNATES)

  for server in "${servers[@]}"; do
    serverHost=$(echo $server | awk -F: '{print $1}')
    serverPort=$(echo $server | awk -F: '{print $2}')
    activeProcess=$(ps -ef | grep "[$firstChar]${backgroundScript:1}.* $server" | awk '{print $2}')
    if [[ -n $activeProcess ]]; then
      greenEcho "\nBackground $backgroundScript process running for $server" >> $logTemp
    fi
  done
}

scriptRun() {
case "$runInterval" in
  "once")
    /config/$backgroundScript.sh $dvr $runInterval \
      && echo "One time run mode used..." >> $logTemp \
      && exit 0
  ;;
  
  "0")
    kill $runningScriptPID $runningSleepPID > $logTemp \
      && echo "Killing script/sleep with PIDs $runningScriptPID/$runningSleepPID for $dvr" >> $logTemp
    rm /config/"$channelsHost"-"$channelsPort"_"$backgroundScript".running
    sleep 2
    lastActive=$(ps -e | grep $backgroundScript | awk '{print $1}')

    if [[ -z $lastActive ]]; then
      sed -i "/#${backgroundScript} title/s/(.*) #/#/" $configTemp
      sed -i "/#${backgroundScript} icon/s|img src = .* width|img src = $purpleIcon width|" $configTemp
      sed -i "/#${backgroundScript} interval default/s/default: .* #/default: once #/" $configTemp
      sed -i "/#${backgroundScript} healthchecks default/s/default: .* #/default: https:\/\/hc-ping.com\/your_custom_uuid #/" $configTemp
      touch $runFile
      exit 0
    fi
    
    touch $runFile
    runningScripts
    exit 0
  ;;

  *)
    [[ -n $runningScriptPID ]] && kill $runningScriptPID $runningSleepPID \
      && echo "Killing currently running script/sleep with PIDs $runningScriptPID/$runningSleepPID" >> $logTemp \
      && sed -i "/#${backgroundScript} title/s/(.*) #/($(date +'%d%b%y_%H:%M')) #/" $configTemp \
      && sed -i "/#${backgroundScript} icon/s|img src = .* width|img src = $greenIcon width|" $configTemp

    echo "Background script initiated, with $runInterval between runs for $dvr" > $logTemp
    [[ "$PERSISTENT_LOGS" == "true" ]] \
      && cat "$logTemp" >> "$logFile" \
      || cat "$logTemp" > "$logFile"
    rm $logTemp
    nohup /config/$backgroundScript.sh $backgroundArguments &>/dev/null &

    grep -q '(.*) #'"$backgroundScript"'' $configTemp
    [[ "$?" == "1" ]] \
      && sed -i "/#${backgroundScript} title/s/#/($(date +'%d%b%y_%H:%M')) #/" $configTemp \
      && sed -i "/#${backgroundScript} icon/s|img src = .* width|img src = $greenIcon width|" $configTemp
            
    sed -i "/#${backgroundScript} interval default/s/default: .* #/default: ${runInterval} #/" $configTemp
    [[ -n $healthchecksIO ]] && echo "Using healthcheck.io pings to $healthchecksIO to confirm functionality" >> $logTemp \
      && sed -i "/#${backgroundScript} healthchecks default/s|default: .* #|default: ${healthchecksIO} #|" $configTemp
    #echo "$dvr $backgroundScript $runInterval $healthchecksIO" > /config/"$channelsHost"-"$channelsPort"_"$backgroundScript".running
    echo "$foregroundArguments" > /config/"$channelsHost"-"$channelsPort"_"$backgroundScript".running

    sleep 2
    runningScripts
    exit 0
  ;;

esac
}

main() {
  cp $configFile /tmp
  scriptRun
}

main
