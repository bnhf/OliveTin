#!/bin/bash

set -x

channelsHost=$(echo $CHANNELS_DVR | awk -F: '{print $1}')
channelsPort=$(echo $CHANNELS_DVR | awk -F: '{print $2}')

python3 /config/channels_to_csv.py -i $channelsHost -p $channelsPort

currentFilename=$(ls channels_dvr_channel_list_*)
tr -d '\r' < $currentFilename > /config/channels_dvr_channel_list_latest.csv

mv channels_dvr_channel_list_* /config