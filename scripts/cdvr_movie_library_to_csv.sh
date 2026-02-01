#!/bin/bash
# cdvr_movie_library_to_csv.sh
# 2026.01.25

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x

dvr=$(echo $1 | sed 's/:/-/')

channelsHost=$(echo $1 | awk -F: '{print $1}')
channelsPort=$(echo $1 | awk -F: '{print $2}')

python3 /config/cdvr_movie_library_to_csv.py -i $channelsHost -p $channelsPort

currentFilename=$(ls channels_dvr_movie_list_*)
tr -d '\r' < $currentFilename > /config/"$dvr"_movie_list_latest.csv

mv channels_dvr_movie_list_* /config
