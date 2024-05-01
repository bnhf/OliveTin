#! /bin/bash

extension=$(basename "$0")
extension=${extension%.sh}
extFile="/config/$extension.env"

envVars=(
"TAG=$1"
"HOST_PORT=$2"
)

printf "%s\n" "${envVars[@]}" > $extFile

/config/portainerstack.sh $extension