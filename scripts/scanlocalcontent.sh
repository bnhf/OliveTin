#!/bin/bash

urlAction=$1

curl -X PUT http://$CHANNELS_DVR/dvr/scanner/$urlAction