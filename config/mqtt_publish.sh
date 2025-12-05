#!/bin/bash

# This script publishes the results from result.json to MQTT.
#
# IMPORTANT: This script does NOT need locking because:
# - It only reads the result.json file created by the main loop
# - It does NOT call vclient or access vcontrold
# - The main loop has already released the lock before calling this script
# - Reading a file is safe even if mqtt_sub.sh is currently holding the lock

# Check if result file exists
if [ ! -f result.json ]; then
    echo "WARNING: result.json not found, skipping MQTT publish"
    exit 0
fi

# Parse and publish each result to MQTT
jq -c '.[]' result.json | while read -r i; do
    COMMAND=$(echo "$i" | jq -r '.command')
    RAW=$(echo "$i" | jq -r '.value')
    PAYLOAD=$(echo "$i" | jq -r '.')
    
    # Validate we have data to publish
    if [ -z "$COMMAND" ]; then
        echo "WARNING: Empty command in result, skipping"
        continue
    fi
    
    # Publish to MQTT
    if mosquitto_pub -u "$MQTTUSER" -P "$MQTTPASSWORD" -h "$MQTTHOST" -p "$MQTTPORT" \
        -t "${MQTTTOPIC}${COMMAND}" -m "$PAYLOAD" -x 120 -c --id "VCONTROLD-PUB" -V "mqttv5"; then
        echo "Published: ${MQTTTOPIC}${COMMAND} = ${RAW}"
    else
        echo "ERROR: Failed to publish ${COMMAND}"
    fi
done
