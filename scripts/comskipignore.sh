#! /bin/bash

channel=$1
curlAction=$2

curl -X $curlAction http://$CHANNELS_DVR/comskip/ignore/channel/$channel