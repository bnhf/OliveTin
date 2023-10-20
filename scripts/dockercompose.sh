#!/bin/bash

dockerCompose=$1

cat /config/$dockerCompose.yaml
[ -f /config/$dockerCompose.env ] || exit 0 && cat /config/$dockerCompose.env 1>&2