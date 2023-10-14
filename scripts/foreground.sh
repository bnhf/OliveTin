#!/bin/bash

#set -x

backgroundScript=$1
runInterval=$2
healthchecksIO=$3
[[ "$healthchecksIO" == "https://hc-ping.com/your_custom_uuid" ]] && healthchecksIO=""
runningScriptPID=$(ps -e | grep $backgroundScript.sh | awk '{print $1}')
#runningSleepPID=$(ps -e | grep sleep | awk '{print $1}')
backgroundArguments="$runInterval $healthchecksIO"

#Trap end of script run
finish() {
  echo "foreground.sh is exiting for $backgroundScript with exit code $?"
  #nohup /config/reload_olivetin.sh &>/dev/null &
  cp /config/config.yaml /config/temp.yaml && cp /config/temp.yaml /config/config.yaml
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
      kill $runningScriptPID \
      && echo "Killing PID $runningScriptPID"
      sed -i "/#${backgroundScript} title/s/(Running!) #/#/" /config/config.yaml \
      && rm /config/$backgroundScript.running
      exit 0
    #fi
    ;;
  *)
    if [[ -z $runningScriptPID ]]; then
      nohup /config/$backgroundScript.sh $backgroundArguments &>/dev/null &
      echo "Background mode initiated, with $runInterval between runs"

      grep -q '(Running!) #'"$backgroundScript"'' /config/config.yaml
      [[ "$?" == "1" ]] && sed -i "/#${backgroundScript} title/s/#/(Running!) #/" /config/config.yaml
            
      sed -i "/#${backgroundScript} interval default/s/once/${runInterval}/" /config/config.yaml
      [[ -n $healthchecksIO ]] && echo "Using healthcheck.io pings to $healthchecksIO to confirm functionality" \
      && sed -i "/#${backgroundScript} healthchecks default/s|https://hc-ping.com/your_custom_uuid|${healthchecksIO}|" /config/config.yaml
      echo "$backgroundScript $runInterval $healthchecksIO" > /config/$backgroundScript.running
      exit 0
    fi

    [[ -n $runningScriptPID ]] && echo "Background script already running: $backgroundScript.sh" \
      && exit 1
    ;;
esac
}

main() {
  scriptRun
}

main