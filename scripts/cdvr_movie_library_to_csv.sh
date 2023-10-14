#!/bin/bash

channelsHost=$(echo $CHANNELS_DVR | awk -F: '{print $1}')
channelsPort=$(echo $CHANNELS_DVR | awk -F: '{print $2}')

python3 /config/cdvr_movie_library_to_csv.py -i $channelsHost -p $channelsPort

mv channels_dvr_movie_list_* /config