#!/bin/bash
# fruitadbt.sh
# 2025.12.26

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x
shopt -s extglob

dvr="$1"
adbtunerSource="$2:$3"
fruitLanes="$4"
fruitSource="$5:$6"
curl -s -o /dev/null http://$adbtunerSource || { echo "ADBTuner not answering on http://$adbtunerSource"; exit 1; }
curl -s -o /dev/null http://$fruitSource || { echo "FruitDeepLinks not answering on http://$fruitSource"; exit 1; }
fruitProviderName=$(echo $7 | awk -F~ '{print $1}')
fruitProviderCode=$(echo $7 | awk -F~ '{print $2}')
  #[[ "$fruitProviderCode" == @(aiv|gametime) ]] && httpDeeplink="&deeplink_format=http" || httpDeeplink=""
  [[ "$fruitProviderCode" == @(aiv) ]] && httpDeeplink="&deeplink_format=http" || httpDeeplink=""
fruitPackageName=$(echo $7 | awk -F~ '{print $3}')
fruitAltPackageName=$(echo $7 | awk -F~ '{print $4}')
configName=$(echo $8 | awk -F~ '{print $1}')
configSource=$(echo $8 | awk -F~ '{print $2}')
  [[ "$configSource" == "custom" ]] && customConfig="$(cat /config/$configName.json)" && configName="$configSource" || customConfig="$(cat $9)"
  rm "$9"
  customConfigUUID=$(printf '%s' "$customConfig" | jq -r '.uuid')
fruitRemove="${10}"
[[ "${11}" == "#" ]] && adbtStartingChannel="" || adbtStartingChannel="${11}"
[[ -n $adbtStartingChannel ]] && adbtIgnoreM3UNumbers="ignore" || adbtIgnoreM3UNumbers=""
[[ -n $customConfigUUID ]] && configUUID="$customConfigUUID" || configUUID="$configName"

deleteExistingFruit() {
  echo -e "[INFO] Deleting existing channels for provider: $fruitRemove..."
  curl -fsS "http://$adbtunerSource/api/v1/channels" -H 'accept: application/json' \
  | jq -r --arg provider "$fruitRemove" '.[] | select(.provider_name == $provider) | .id' \
  | while read -r adbtunerChannel; do
      [[ -z "$adbtunerChannel" ]] && continue
      fruitChannel="http://$adbtunerSource/api/v1/channels/$adbtunerChannel"
      echo -e "\nDELETE $fruitRemove $fruitChannel"
      curl -sS -X DELETE "$fruitChannel"
    done
  echo -e "\n[INFO] Deletion of existing channels for provider: $fruitRemove completed."
}

createFruitConfig() {
  local configURL="http://${adbtunerSource}/api/v1/configuration"
  local configsURL="http://${adbtunerSource}/api/v1/configurations"

  echo "[INFO] Checking for configuration ${customConfigUUID} at ${configsURL}"

  local allConfigs
  if ! allConfigs=$(curl -sS -X GET "${configsURL}" -H 'accept: application/json'); then
    echo "[ERROR] Failed to fetch configurations from ${configsURL}"
    return 1
  fi

  if echo "${allConfigs}" | jq -e --arg uuid "${customConfigUUID}" '
      (map(select(
        (.uuid == $uuid) or
        (.json_data.uuid == $uuid)
      )) | length) > 0
    ' >/dev/null 2>&1; then
    echo "[INFO] Configuration ${customConfigUUID} already exists. Deleting it..."

    local deleteHttpReturnCode
    deleteHttpReturnCode=$(curl -sS -o /tmp/fruit_config_delete_response.json -w '%{http_code}' \
      -X DELETE "${configsURL}/${customConfigUUID}" \
      -H 'accept: application/json')

    if [[ "${deleteHttpReturnCode}" =~ ^2 ]]; then
      echo "[INFO] Configuration deleted successfully (HTTP ${deleteHttpReturnCode})."
    else
      echo "[ERROR] Failed to delete configuration (HTTP ${deleteHttpReturnCode}). Response:"
      cat /tmp/fruit_config_delete_response.json
      echo
      return 1
    fi
  fi

  echo "[INFO] Posting configuration ${customConfigUUID}..."

  local postHttpReturnCode
  postHttpReturnCode=$(curl -sS -o /tmp/fruit_config_post_response.json -w '%{http_code}' \
    -X POST "${configURL}" \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -d "{\"json_data\": ${customConfig}}")

  if [[ "${postHttpReturnCode}" =~ ^2 ]]; then
    echo "[INFO] Configuration created successfully (HTTP ${postHttpReturnCode})."
  else
    echo "[ERROR] Failed to create configuration (HTTP ${postHttpReturnCode}). Response:"
    cat /tmp/fruit_config_post_response.json
    echo
    return 1
  fi
}

generateM3UID() {
  python3 - <<'EOF'
import uuid
print(uuid.uuid4().int)
EOF
}

createFruitLanes() {
  echo -e "\n[INFO] Creating $fruitLanes lanes for provider: $fruitProviderName"
  for ((fruitLane=1; fruitLane<=fruitLanes; fruitLane++)); do
    jq -n \
      --arg m3u_id "${fruitProviderCode}$(printf '%02d' "$fruitLane")" \
      --arg provider "${fruitProviderCode}" \
      --argjson number $(( fruitLane - 1 + adbtStartingChannel )) \
      --arg name "${fruitProviderName} ${fruitLane}" \
      --arg package "${fruitPackageName}" \
      --arg alt_package "${fruitAltPackageName}" \
      --arg url "http://$fruitSource/api/adb/lanes/${fruitProviderCode}/${fruitLane}/deeplink?format=json${httpDeeplink}&dynamic_url_json_key=deeplink" \
      --arg config "${configUUID}" \
      '{
        m3u_id: $m3u_id,
        provider_name: $provider,
        number: $number,
        name: $name,
        package_name: $package,
        alternate_package_name: $alt_package,
        url_or_identifier: $url,
        configuration_uuid: $config,
        tvc_guide_stationid: "",
        guide_offset_hours: "",
        data: null,
        id: 0
      }' |
      curl -fsS "http://$adbtunerSource/api/v1/channels" \
        -H 'accept: application/json' \
        -H 'Content-Type: application/json' \
        -d @- \
      || { echo "POST failed for lane $fruitLane" >&2; return 1; }

    echo "Created channel: $name"
  done
  echo -e "[INFO] Creation of $fruitLanes lanes for provider: $fruitProviderName completed."
}

customChannels() {
cat <<EOF
{
  "name": "ADBTuner - $fruitProviderName",
  "type": "MPEG-TS",
  "source": "URL",
  "url": "http://$adbtunerSource/channels.m3u8?provider=$fruitProviderCode",
  "text": "",
  "refresh": "24",
  "limit": "",
  "satip": "",
  "numbering": "$adbtIgnoreM3UNumbers",
  "start_number": "$adbtStartingChannel",
  "logos": "",
  "xmltv_url": "http://$fruitSource/out/adb_lanes.xml",
  "xmltv_refresh": "3600"
}
EOF
}

cdvrCustomSource() {
  echo -e "\n[INFO] Updating Custom Source in CDVR for ADBTuner provider: $fruitProviderName..."
  customChannelsJSON=$(echo -n "$(customChannels)" | tr -d '\n')

  echo -e "JSON response from $dvr:" \
  && curl -s -X PUT -H "Content-Type: application/json" -d "$customChannelsJSON" "http://$dvr/providers/m3u/sources/ADBTuner-${fruitProviderName// /}"
  echo -e "\n[INFO] CDVR Custom Source update completed for ADBTuner provider: $fruitProviderName"
}

main() {
  [[ "$fruitLanes" == "0" && "$fruitRemove" != "none" ]] && deleteExistingFruit && exit 0
  [[ "$fruitRemove" != "none" ]] && deleteExistingFruit && echo
  [[ "$configName" == "custom" && -n $customConfigUUID ]] && createFruitConfig
  createFruitLanes
  cdvrCustomSource
}

main
