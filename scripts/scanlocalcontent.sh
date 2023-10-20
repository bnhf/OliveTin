#!/bin/bash

set -x

dvr=$1
urlAction=$2

curl -X PUT http://$dvr/dvr/scanner/$urlActionction