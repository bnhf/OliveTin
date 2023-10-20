#!/bin/bash

set -x

dvr=$1

channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')

python3 /config/cdvr_movie_library_to_csv.py -i $channelsHost -p $channelsPort

currentFilename=$(ls channels_dvr_movie_list_*)
tr -d '\r' < $currentFilename > /config/"$dvr"_movie_list_latest.csv

mv channels_dvr_movie_list_* /config