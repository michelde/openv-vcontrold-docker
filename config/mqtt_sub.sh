#!/bin/bash

# This script subscribes to a MQTT topic using mosquitto_sub.
# On each message received, you can execute whatever you want.

while true  # Keep an infinite loop to reconnect when connection lost/broker unavailable
do
    mosquitto_sub -u $MQTTUSER -P $MQTTPASSWORD -h $MQTTHOST -p $MQTTPORT -t $MQTTTOPIC/commands -I "VCONTROLD-SUB" | while read -r payload
    do
        # Here is the callback to execute whenever you receive a message:
        echo "Rx MQTT: ${payload}"
        vclient -h 127.0.0.1 -p 3002 -J -c "${payload}" -o /etc/vcontrold/command_result.json
        result=$(cat /etc/vcontrold/command_result.json | jq -r '.[]')
        echo "Result: ${result}"
    done
    sleep 10  # Wait 10 seconds until reconnection
done & # Discomment the & to run in background (but you should rather run THIS script in background)
