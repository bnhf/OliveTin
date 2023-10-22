#!/bin/bash

set -x

dvr=$(echo $1 | sed 's/:/-/')

channelsHost=$(echo $1 | awk -F: '{print $1}')
channelsPort=$(echo $1 | awk -F: '{print $2}')

python3 /config/channels_to_csv.py -i $channelsHost -p $channelsPort

currentFilename=$(ls channels_dvr_channel_list_*)
tr -d '\r' < $currentFilename > /config/"$dvr"_channel_list_latest.csv

mv channels_dvr_channel_list_* /config