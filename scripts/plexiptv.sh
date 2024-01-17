#!/bin/bash

set -x

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
runInterval=$2
healthchecksIO=$3
logFile=/config/"$channelsHost"-"$channelsPort"_plexiptv_latest.log
runFile=/tmp/"$channelsHost"-"$channelsPort"_plexiptv.run
plexData=/config/"$channelsHost"-"$channelsPort"_data/plexdata.txt

while true; do
  if ! [ -f $plexData ]; then
    echo "Plex token data file not found." >> $logFile
    echo "Have you run the Generate Plex Token OliveTin Action?" >> $logFile
    exit 1
  fi

  cd /tmp

  # Get user specific vars
  sessionID="$(grep -Po 'SESSIONID=\K[^,]+' $plexData)"
  clientID="$(grep -Po 'CLIENTID=\K[^,]+' $plexData)"
  plexToken="$(grep -Po 'TOKEN=\K[^,]+' $plexData)"

  # Download m3u/epg
  wget -nv 'https://i.mjh.nz/Plex/us.m3u8' -O us.m3u8 &>> $logFile || exit
  wget -nv 'https://i.mjh.nz/Plex/us.xml' -O us.xml &>> $logFile || exit

  # Change the stream links
  sed -i 's!#EXTM3U.*!#EXTM3U!' us.m3u8
  sed -i 's!https://i.mjh.nz/Plex!https://epg.provider.plex.tv/library/parts!' us.m3u8
  sed -i "s!m3u8!m3u8?X-Plex-Product=Plex%20Web\&X-Plex-Session-Id=${sessionID}\&X-Plex-Client-Identifier=${clientID}\&X-Plex-Client-Platform=Chrome\&X-Plex-Token=${plexToken}!" us.m3u8

  # Timestamp
  #echo Last Run $(date) >index.log
  echo Last Run $(date) >> $logFile

  cp us.* /config/"$channelsHost"-"$channelsPort"_data

  # Update DVR
  #curl -XPOST http://$dvr/providers/m3u/sources/Plex/refresh >/dev/null 2>&1
  #curl -XPUT http://$dvr/dvr/lineups/XMLTV-Plex >/dev/null 2>&1

  [[ $runInterval == "once" ]] \
    && touch $runFile \
    && exit 0

  [[ -n $healthchecksIO ]] \
    && curl -m 10 --retry 5 $healthchecksIO

  [[ $runInterval != "once" ]] \
    && touch $runFile \
    && sleep $runInterval
done

exit