#!/bin/bash
sleep 3
# search the USB device as it sometimes is USB0 or USB1
USB_DEVICE=`find /dev/ -name ttyUSB*`
echo "Device ${USB_DEVICE}"
# make device accessable
chmod 777 ${USB_DEVICE}
cp /config/* /etc/vcontrold/
# set the USB device in the vcontrold.xml settings file
sed -i -e "/<serial>/,/<\/serial>/ s|<tty>[0-9a-z\/._A-Z:]\{1,\}</tty>|<tty>$USB_DEVICE</tty>|g" /etc/vcontrold/vcontrold.xml
vcontrold -x /etc/vcontrold/vcontrold.xml -P /var/run/vcontrold.pid

status=$?
pid=$(pidof vcontrold)
if [ $status -ne 0 ];then
	echo "Failed to start vcontrold"
fi

if [ $MQTTACTIVE = true ]; then
	echo "vcontrold gestartet (PID $pid)"
	echo "MQTT: aktiv (var = $MQTTACTIVE)"
	echo "Aktualisierungsintervall: $INTERVAL sec"
	while sleep $INTERVAL; do
		vclient -h 127.0.0.1 -p 3002 -f /etc/vcontrold/1_mqtt_commands.txt -t /etc/vcontrold/2_mqtt.tmpl -x /etc/vcontrold/3_mqtt_pub.txt
		if [ -e /var/run/vcontrold.pid ]; then
			:
		else
			echo "vcontrold.pid nicht vorhanden, exit 0"
			exit 0
		fi
	done
else
	echo "vcontrold gestartet"
	echo "MQTT: inaktiv (var = $MQTTACTIVE)"
	echo "PID: $pid"
	while sleep 600; do
		if [ -e /var/run/vcontrold.pid ]; then
			:
		else
			echo "vcontrold.pid nicht vorhanden, exit 0"
			exit 0
		fi
	done
fi
