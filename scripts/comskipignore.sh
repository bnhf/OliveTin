#! /bin/bash

dvr=$1
channel=$2
curlAction=$3

curl -X $curlAction http://$dvr/comskip/ignore/channel/$channel