#!/bin/bash
# olivetin-for-channels.sh
# 2025.04.01

set -x

extension=$(basename "$0")
extension=${extension%.sh}

[[ -f /config/$extension.env ]] \
   && cp /config/$extension.env /tmp
envFile="/tmp/$extension.env"
dirsFile="/tmp/$extension.dirs"

[[ -f /config/$extension.yaml ]] \
   && cp /config/$extension.yaml /tmp \
   && yamlCopied="true"
yamlFile="/tmp/$extension.yaml"

portainerHost="$(grep PORTAINER_HOST= $envFile | awk -F= '{print $2}')"
portainerToken="$(grep PORTAINER_TOKEN= $envFile | awk -F'TOKEN=' '{print $2}')"
portainerPort="$(grep PORTAINER_PORT= $envFile | awk -F= '{print $2}')"

envVarsUpdated="$1"
[[ ! -f /config/$extension.env || "$envVarsUpdated" != "true" || -z $portainerToken ]] \
  && echo "Run the OliveTin Environment Variables Generator/Tester Action first, and then come back here..." \
  && exit 0
[[ -f /config/$extension.env ]] \
   && cp /config/$extension.env /tmp
containerTag="$2"
  [[ -n $containerTag ]] && sed -i "s/^TAG=.*/TAG=$containerTag/" $envFile
containerSuffix="$3"
  [[ -n $containerSuffix ]] && echo "EZ_START=$containerSuffix" >> $envFile
hostPort="$4"
  [[ -n $hostPort ]] && sed -i "s/^HOST_PORT=.*/HOST_PORT=$hostPort/" $envFile
hostDir="$5"
  [[ -n $hostDir ]] && sed -i "s|^HOST_DIR=.*|HOST_DIR=$hostDir|" $envFile
hostSFSPort="$6"
  [[ -n $hostSFSPort ]] && sed -i "s/^HOST_PORT=.*/HOST_SFS_PORT=$hostSFSPort/" $envFile
volumeDVR1="$7"
  [[ "$volumeDVR1" == "true" ]] && sed -i -E 's/#(0|1)#//g' $yamlFile
volumeLogs1="$8"
  [[ "$volumeLogs1" == "true" ]] && sed -i -E 's/#(0|2)#//g' $yamlFile
volumeTubearchivist1="$9"
  [[ "$volumeTubearchivist1" == "true" ]] && sed -i -E 's/#(0|3)#//g' $yamlFile
volumeDVR2="${10}"
  [[ "$volumeDVR2" == "true" ]] && sed -i -E 's/#(0|4)#//g' $yamlFile
volumeLogs2="${11}"
  [[ "$volumeLogs2" == "true" ]] && sed -i -E 's/#(0|5)#//g' $yamlFile
volumeTubearchivist2="${12}"
  [[ "$volumeTubearchivist2" == "true" ]] && sed -i -E 's/#(0|6)#//g' $yamlFile
volumeDVR3="${13}"
  [[ "$volumeDVR3" == "true" ]] && sed -i -E 's/#(0|7)#//g' $yamlFile
volumeLogs3="${14}"
  [[ "$volumeLogs3" == "true" ]] && sed -i -E 's/#(0|8)#//g' $yamlFile
volumeTubearchivist3="${15}"
  [[ "$volumeTubearchivist3" == "true" ]] && sed -i -E 's/#(0|9)#//g' $yamlFile

sed -i '/=#/d' $envFile

synologyDirs=(
"$5/olivetin/data"
)

printf "%s\n" "${synologyDirs[@]}" > $dirsFile

/config/portainerstack.sh $extension $portainerHost $portainerToken $portainerPort $yamlCopied

[[ $? == 1 ]] && exit 1 || exit 0
