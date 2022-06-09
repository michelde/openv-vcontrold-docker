#!/bin/bash
jq -c '.[]' result.json | while read i; do
    COMMAND=$(echo $i | jq -r ' .command')
    RAW=$(echo $i | jq -r ' .value')
    PAYLOAD=$(echo $i | jq -r '. ')
    #echo $PAYLOAD
    mosquitto_pub -u $MQTTUSER -P $MQTTPASSWORD -h $MQTTHOST -p $MQTTPORT -t $MQTTTOPIC/$COMMAND -m "$PAYLOAD" -x 120 -c --id "VCONTROLD-PUB" -V "mqttv5"
done
