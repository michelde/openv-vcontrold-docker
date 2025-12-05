#!/bin/bash

# This script subscribes to a MQTT topic using mosquitto_sub.
# On each message received, it executes commands via vclient.
#
# IMPORTANT: This script uses the vclient_with_lock function from startup.sh
# to prevent race conditions when multiple commands are executed simultaneously.

echo "MQTT subscription handler starting..."
echo "Subscribing to: ${MQTTTOPIC}commands"

# Counter for processed commands
command_count=0

while true  # Keep an infinite loop to reconnect when connection lost/broker unavailable
do
    mosquitto_sub -u "$MQTTUSER" -P "$MQTTPASSWORD" -h "$MQTTHOST" -p "$MQTTPORT" -t "${MQTTTOPIC}commands" -I "VCONTROLD-SUB" | while read -r payload
    do
        # Increment command counter
        command_count=$((command_count + 1))
        
        # Log received command
        echo "[MQTT-CMD-${command_count}] Received: ${payload}"
        
        # Validate payload is not empty
        if [ -z "$payload" ]; then
            echo "[MQTT-CMD-${command_count}] ERROR: Empty payload received, ignoring"
            continue
        fi
        
        # Use lock mechanism to prevent conflicts with periodic reads
        echo "[MQTT-CMD-${command_count}] Acquiring lock..."
        
        # Execute vclient with locking (function exported from startup.sh)
        if vclient_with_lock "${payload}" "/tmp/mqtt_command_result_${command_count}.json"; then
            # Parse and log result
            if [ -f "/tmp/mqtt_command_result_${command_count}.json" ]; then
                result=$(jq -r '.[]' "/tmp/mqtt_command_result_${command_count}.json" 2>/dev/null || echo "Error parsing JSON")
                echo "[MQTT-CMD-${command_count}] Result: ${result}"
                
                # Optional: Publish result back to MQTT (uncomment if needed)
                # mosquitto_pub -u "$MQTTUSER" -P "$MQTTPASSWORD" -h "$MQTTHOST" -p "$MQTTPORT" \
                #     -t "${MQTTTOPIC}command_result" -m "${result}"
                
                # Cleanup
                rm -f "/tmp/mqtt_command_result_${command_count}.json"
            else
                echo "[MQTT-CMD-${command_count}] WARNING: Result file not created"
            fi
        else
            echo "[MQTT-CMD-${command_count}] ERROR: vclient command failed"
        fi
        
        echo "[MQTT-CMD-${command_count}] Lock released"
    done
    
    # If we get here, connection was lost
    echo "MQTT connection lost, reconnecting in 10 seconds..."
    sleep 10
done
