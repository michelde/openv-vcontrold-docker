# openv-vcontrold-docker

Viessmann Optolink Control based on OpenV library.
This container uses the vcontrold deamon and connect to a Viessmann heating system. To get get the values, the `vclient` tool is used and afterwards published to a mqtt broker.

## Hardware requirements

To get this working you need an optolink adatper which is connected to the host system. When starting this docker image you need to pass the device into the docker container. As something like /dev/ttyUSB0 can change/vary on reboot, I would recommend to use the serial id from the optolink adapter. See example in below docker-compose.yaml file.

## Software requirements

A Mqtt broker is required in your environment where this container will send the values to.

## Configuration

The container expects to have the configuration passed as environment variables. You need either to pass this when starting the container usind the option -e or you can also create a `.env` file for a docker-compose screnario.

### MQTT

For the mqtt broker you need to define the following environment variables:
| variable      | desscription     | example value  |
| ------------- | ------------- | -----|
| MQTTACTIVE    | flag to set mqtt active | `true` or `false` |
| MQTTHOST      | hostname for mqtt broker | `192.168.1.2` or `broker.home` |
| MQTTPORT      | port for mqtt broker     |  `1883` |
| MQTTTOPIC     | prefix for topic followed by the command | `smarthome/optolink/` |
| MQTTUSER      | if mqtt broker requires authentification |  `mqtt_user` |
| MQTTPASSWORD  | if mqtt broker requires authentification |  `secret123` |

### Read interval

The environment variable `INTERVAL` defines the time in seconds

### vcontrol daemon

Make sure to adjust the `vcontrold.xml` and `vito.xml` to fit your Viessmann heating system.

## Starting the container

The easiest way is to create a `docker-compose.yaml` file. Here is an example file:

```yaml
version: '3.1'
services:
  vcontrold:
    image: michelmu/vcontrold-openv
    container_name: vcontrold
    restart: always
    devices:
      - /dev/serial/by-id/usb-FTDI_FT232R_USB_UART_AL00AKZQ-if00-port0:/dev/ttyUSB0
    environment:
      MQTTHOST: ${MQTTHOST}
      MQTTPORT: ${MQTTPORT}
      MQTTTOPIC: ${MQTTTOPIC}
      MQTTPASSWORD: ${MQTTPASSWORD}
      MQTTACTIVE: ${MQTTACTIVE}
      MQTTUSER: ${MQTTUSER}
      INTERVAL: ${INTERVAL}
    volumes:
      - ./config:/etc/vcontrold/

```

In order to pass the environment variables you can use the `.env` file and set the variables according to your needs.
