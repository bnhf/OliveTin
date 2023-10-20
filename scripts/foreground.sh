#!/bin/bash

#set -x

backgroundScript=$1
runInterval=$2
healthchecksIO=$3
[[ "$healthchecksIO" == "https://hc-ping.com/your_custom_uuid" ]] && healthchecksIO=""
runningScriptPID=$(ps -e | grep $backgroundScript.sh | awk '{print $1}')
[[ -n $runningScriptPID ]] && runningSleepPID=$(ps --ppid $runningScriptPID | grep sleep | awk '{print $1}')
backgroundArguments="$runInterval $healthchecksIO"
greenIcon=\"icons\/channels.png\"
purpleIcon=\"https:\/\/community-assets.getchannels.com\/original/2X/5/55232547f7e8f243069080b6aec0c71872f0f537.png\"

#Trap end of script run
finish() {
  echo "background.sh is exiting for $backgroundScript with exit code $?"
  #nohup /config/reload_olivetin.sh &>/dev/null &
  cp /config/config.yaml /config/temp.yaml && cp /config/temp.yaml /config/config.yaml
  sleep 1
  [ -f /config/$backgroundScript.log ] && cat /config/$backgroundScript.log
}

trap finish EXIT

scriptRun() {
case "$runInterval" in
  "once")
    #[[ -z $runningScriptPID ]] && /config/$backgroundScript.sh $runInterval \
    /config/$backgroundScript.sh $runInterval \
      && echo "One time run mode used..." \
      && exit 0
    
    #[[ -n $runningScriptPID ]] && echo "Background script already running for $backgroundScript" \
      #&& exit 1
    ;;
  "0")
    #if [[ -n $runningScriptPID ]]; then
      kill $runningScriptPID $runningSleepPID \
      && echo "Killing script/sleep with PIDs $runningScriptPID/$runningSleepPID"
      sed -i "/#${backgroundScript} title/s/(.*) #/#/" /config/config.yaml \
      && rm /config/$backgroundScript.running
      sed -i "/#${backgroundScript} icon/s|img src = .* width|img src = $purpleIcon width|" /config/config.yaml
      sed -i "/#${backgroundScript} interval default/s/default: .* #/default: once #/" /config/config.yaml
      sed -i "/#${backgroundScript} healthchecks default/s/default: .* #/default: https:\/\/hc-ping.com\/your_custom_uuid #/" /config/config.yaml
      exit 0
    #fi
    ;;
  *)
    #if [[ -z $runningScriptPID ]]; then
      [[ -n $runningScriptPID ]] && kill $runningScriptPID $runningSleepPID \
      && echo "Killing currently running script/sleep with PIDs $runningScriptPID/$runningSleepPID" \
      && sed -i "/#${backgroundScript} title/s/(.*) #/($(date +'%d%b%y_%H:%M')) #/" /config/config.yaml \
      && sed -i "/#${backgroundScript} icon/s|img src = .* width|img src = $greenIcon width|" /config/config.yaml

      nohup /config/$backgroundScript.sh $backgroundArguments &>/dev/null &
      echo "Background mode initiated, with $runInterval between runs"

      grep -q '(.*) #'"$backgroundScript"'' /config/config.yaml
      [[ "$?" == "1" ]] \
      && sed -i "/#${backgroundScript} title/s/#/($(date +'%d%b%y_%H:%M')) #/" /config/config.yaml \
      && sed -i "/#${backgroundScript} icon/s|img src = .* width|img src = $greenIcon width|" /config/config.yaml
            
      sed -i "/#${backgroundScript} interval default/s/default: .* #/default: ${runInterval} #/" /config/config.yaml
      [[ -n $healthchecksIO ]] && echo "Using healthcheck.io pings to $healthchecksIO to confirm functionality" \
      && sed -i "/#${backgroundScript} healthchecks default/s|default: .* #|default: ${healthchecksIO} #|" /config/config.yaml
      echo "$backgroundScript $runInterval $healthchecksIO" > /config/$backgroundScript.running
      exit 0
    #fi

    #[[ -n $runningScriptPID ]] && echo "Background script already running: $backgroundScript.sh" \
      #&& exit 1
    ;;
esac
}

main() {
  scriptRun
}

main