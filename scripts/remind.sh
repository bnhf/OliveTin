#!/bin/bash
# remind.sh
# 2025.05.05

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x

dvr=$1
channelsHost=$(echo "$dvr" | awk -F: '{print $1}')
channelsPort=$(echo "$dvr" | awk -F: '{print $2}')
foregroundScript=remind
backgroundScript=reminder
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
      echo "Background Event Reminder running for $server"
    fi
  done
}

scriptKill() {
  runningScriptPID=$(ps -ef | grep "[$firstChar]${backgroundScript:1}.* $dvr" | awk '{print $2}')
  [[ -n $runningScriptPID ]] && runningSleepPID=$(ps --ppid $runningScriptPID | grep sleep | awk '{print $1}')
  kill $runningScriptPID $runningSleepPID >> $logFile \
    && echo "Killing script/sleep with PIDs $runningScriptPID/$runningSleepPID for $dvr" >> $logFile
  rm /config/"$channelsHost"-"$channelsPort"_remind.running
  echo "Killing Event Reminder PID $runningScriptPID"
  sleep 2
  lastActive=$(ps -e | grep "[$firstChar]${backgroundScript:1}.* $dvr" | awk '{print $1}')

  if [[ -z $lastActive ]]; then
    sed -i "/#${foregroundScript} icon/s|img src = .* width|img src = $purpleIcon width|" $configTemp
    sed -i "/#${foregroundScript} title/s/(.*) #/#/" $configTemp
    sed -i "/#${foregroundScript} frequency default/s/default: .* #/default: 5 #/" $configTemp
    sed -i "/#${foregroundScript} padding_key default/s/default: .* #/default: 10 #/" $configTemp
    sed -i "/#${foregroundScript} apprise_url default/s|default: .* #|default: channels:// #|" $configTemp
    sed -i "/#${foregroundScript} delete_job default/s/default: .* #/default: \"false\" #/" $configTemp
    sed -i "/#${foregroundScript} check_extra default/s/default: .* #/default: 10 #/" $configTemp
    sed -i "/#${foregroundScript} channel_change default/s/default: .* #/default: none #/" $configTemp
    exit 0
  fi

  runningScripts
  exit 0
}

cp $configFile /tmp
frequency=$2
  [[ "$frequency" == "0" ]] && scriptKill
  [[ "$frequency" != "5" ]] \
  && sed -i "/#${foregroundScript} frequency default/s/default: .* #/default: ${frequency} #/" $configTemp
padding_key=$3
  [[ "$padding_key" != "10" ]] \
  && sed -i "/#${foregroundScript} padding_key default/s/default: .* #/default: ${padding_key} #/" $configTemp
apprise_url=$4
  [[ "$apprise_url" != "channels://" ]] \
  && sed -i "/#${foregroundScript} apprise_url default/s|default: .* #|default: ${apprise_url} #|" $configTemp
delete_job=$5
  [[ "$delete_job" != "false" ]] \
  && sed -i "/#${foregroundScript} delete_job default/s|default: .* #|default: \"${delete_job}\" #|" $configTemp
check_extra=$6
  [[ "$check_extra" != "10" ]] \
  && sed -i "/#${foregroundScript} check_extra default/s|default: .* #|default: \"${check_extra}\" #|" $configTemp
channel_change=$7
  [[ "$channel_change" != "none" ]] \
  && sed -i "/#${foregroundScript} channel_change default/s|default: .* #|default: \"${channel_change}\" #|" $configTemp
#backgroundArguments="$dvr $frequency $padding_key \"$apprise_url\" $delete_job"

scriptRun() {
  runningScriptPID=$(ps -ef | grep "[$firstChar]${backgroundScript:1}.* $dvr" | awk '{print $2}')
  [[ -n $runningScriptPID ]] && kill $runningScriptPID && echo "Killing currently running script with PID $runningScriptPID" \
  && sed -i "/#${foregroundScript} title/s/(.*) #/($(date +'%d%b%y_%H:%M')) #/" $configTemp \
  && sed -i "/#${foregroundScript} icon/s|img src = .* width|img src = $greenIcon width|" $configTemp
  nohup /config/$backgroundScript.sh $dvr $frequency $padding_key "$apprise_url" $delete_job $check_extra $channel_change &>/dev/null &
  runningScriptPID=$!
  echo "$foregroundScript.sh $dvr $frequency $padding_key \"$apprise_url\" $delete_job $check_extra $channel_change" > /config/"$channelsHost"-"$channelsPort"_remind.running

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
