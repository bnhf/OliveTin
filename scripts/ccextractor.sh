#!/bin/bash

set -x

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
dvrDir="$channelsHost-$channelsPort"
ccextractorPath="$2"
ccextractorMPG="$3"
ccextractorSRT="${ccextractorMPG%.mpg}.srt"

cd "/mnt/$dvrDir/$ccextractorPath"
ccextractor -ts -srt "$ccextractorMPG" -o "$ccextractorSRT"
cd /