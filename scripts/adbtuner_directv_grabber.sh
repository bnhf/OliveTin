#!/bin/bash
# adbtuner_directv_grabber.sh
# 2025.12.12

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x

dvr="$1"
adbtunerSource="$2:$3"
customConfig="$(cat $4)"
  rm "$4"
customConfigUUID=$(printf '%s' "$customConfig" | jq -r '.uuid')
[[ "$5" == "false" ]] && directvRemove="" || directvRemove="$5"
[[ "$6" == "#" ]] && adbtStartingChannel="" || adbtStartingChannel="$6"
[[ -n $adbtStartingChannel ]] && adbtIgnoreM3UNumbers="ignore" || adbtIgnoreM3UNumbers=""
urlScheme="$7"

allchannelsGuideJSON=$(cat)

deleteExistingDirecTV() {
  curl -fsS "http://$adbtunerSource/api/v1/channels" -H 'accept: application/json' \
  | jq -r --arg p "DirecTV" '.[] | select(.provider_name == $p) | .id' \
  | while read -r adbtunerChannel; do
      [[ -z "$adbtunerChannel" ]] && continue
      directvChannel="http://$adbtunerSource/api/v1/channels/$adbtunerChannel"
      echo -e "\nDELETE $directvChannel"
      curl -sS -X DELETE "$directvChannel"
    done
}

createDirecTVJSON() {
  adbtunerDirecTVJSON=$(
    printf '%s\n' "$allchannelsGuideJSON" \
    | jq --arg uuid "$customConfigUUID" --arg scheme "$urlScheme" '
      [
        .channelInfoList[]
        | {
            m3u_id: "",
            provider_name: "DirecTV",
            number: (.channelNumber | tonumber),
            name: .channelName,
            package_name: "com.att.tv",
            alternate_package_name: "com.att.tv.openvideo",
            url_or_identifier: ($scheme + .callSign + "/" + .resourceId),
            configuration_uuid: ($uuid // ""),
            tvc_guide_stationid: (.externalListingId // ""),
            guide_offset_hours: "",
            data: null,
            id: 0
          }
      ]
    '
  )
}

createDirecTVConfig() {
  local getURL="http://${adbtunerSource}/api/v1/configurations"
  local postURL="http://${adbtunerSource}/api/v1/configuration"

  echo "[INFO] Checking for configuration ${customConfigUUID} at ${getURL}"

  local allConfigs
  if ! allConfigs=$(curl -sS -X GET "${getURL}" -H 'accept: application/json'); then
    echo "[ERROR] Failed to fetch configurations from ${getURL}"
    return 1
  fi

  if echo "${allConfigs}" | jq -e --arg uuid "${customConfigUUID}" '
      (map(select(
        (.uuid == $uuid) or
        (.json_data.uuid == $uuid)
      )) | length) > 0
    ' >/dev/null 2>&1; then
    echo "[INFO] Configuration ${customConfigUUID} already exists. Nothing to do."
    return 0
  fi

  echo "[INFO] Configuration ${customConfigUUID} not found. Creating it via POST ${postURL} ..."

  local httpReturnCode
  httpReturnCode=$(curl -sS -o /tmp/directv_config_post_response.json -w '%{http_code}' \
    -X POST "${postURL}" \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -d "{\"json_data\": ${customConfig}}")

  if [[ "${httpReturnCode}" =~ ^2 ]]; then
    echo "[INFO] Configuration created successfully (HTTP ${httpReturnCode})."
  else
    echo "[ERROR] Failed to create configuration (HTTP ${httpReturnCode}). Response:"
    cat /tmp/directv_config_post_response.json
    echo
    return 1
  fi
}

createDirecTVChannels() {
  jq -c '.[]' \
  | while IFS= read -r channelJSON; do
      curl -fsS \
        -X POST "http://${adbtunerSource}/admin/channel" \
        -H 'Content-Type: application/x-www-form-urlencoded' \
        -d "$(printf '%s' "$channelJSON" | jq -r '"number=\(.number | @uri)&provider_name=\(.provider_name | @uri)&name=\(.name | @uri)&url_or_identifier=\(.url_or_identifier | @uri)&package_name=\(.package_name | @uri)&alternate_package_name=\(.alternate_package_name | @uri)&tvc_guide_stationid=\(.tvc_guide_stationid // "" | @uri)&guide_offset_hours=\(.guide_offset_hours // "0" | @uri)&configuration_option=\(.configuration_uuid // "" | @uri)"')" \
      || {
        echo "POST FAILED for channel: $channelJSON" >&2
        return 1
      }
    done

  echo "Created ADBTuner - DirecTV channels"
}

processAlternateChannelNumbers() {
  jq '
    group_by(.number)
    | map(
        if length == 1 then
          .[0]
        else
          sort_by(if .name | test("ALT-|ALT |Alternate|Overflow"; "i") then 1 else 0 end, (.name | length), .name)
          | to_entries
          | map(
              .key as $idx
              | .value
              | if $idx == 0 then
                  .
                else
                  .number = ((.number | tostring) + "." + ($idx | tostring))
                end
            )
        end
      )
    | flatten
  '
}

customChannels() {
cat <<EOF
{
  "name": "ADBTuner - DirecTV",
  "type": "MPEG-TS",
  "source": "URL",
  "url": "http://$adbtunerSource/channels.m3u8?provider=DirecTV",
  "text": "",
  "refresh": "24",
  "limit": "",
  "satip": "",
  "numbering": "$adbtIgnoreM3UNumbers",
  "start_number": "$adbtStartingChannel",
  "logos": "",
  "xmltv_url": "",
  "xmltv_refresh": "3600"
}
EOF
}

cdvrCustomSource() {
  customChannelsJSON=$(echo -n "$(customChannels)" | tr -d '\n')

  echo -e "\nJSON response from $dvr:" \
  && curl -s -X PUT -H "Content-Type: application/json" -d "$customChannelsJSON" http://$dvr/providers/m3u/sources/ADBTuner-DirecTV
}

main() {
  [[ $directvRemove ]] && deleteExistingDirecTV && echo
  createDirecTVJSON
  [[ $customConfigUUID ]] && createDirecTVConfig
  echo "$adbtunerDirecTVJSON" | processAlternateChannelNumbers | createDirecTVChannels
  cdvrCustomSource
}

main
