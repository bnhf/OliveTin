#!/bin/bash
# channels_to_csv.sh
# 2026.01.06

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')

python3 /config/channels_to_csv.py -i $channelsHost -p $channelsPort

currentFilename=$(ls channels_dvr_channel_list_*)
tr -d '\r' < $currentFilename > /config/"$channelsHost"-"$channelsPort"_channel_list_latest.csv

mv channels_dvr_channel_list_* /config
