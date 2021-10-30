# openv-vcontrold-docker

Viessmann Optolink Control based on OpenV library.
This container uses the vcontrold deamon and connect to a Viessmann heating system. To get get the values, the `vclient` tool is used and afterwards published to a mqtt broker.

## Hardware requirements

To get this working you need an optolink adatper which is connected to the host system. When starting this docker image you need to pass the device into the docker container. As something like /dev/ttyUSB0 can change/vary on reboot, I would recommend to use the serial id from the optolink adapter. See example in below docker-compose.yaml file.

## Software requirements

A Mqtt broker is required in your environment where this container will send the values to. If you just want to test the vclient to get values set MQTTACTIVE = false. Then you can login to the container `docker exec -it openv-vcontrol-docker bash`. In the shell you can then test your commands e.g. `vclient -h 127.0.0.1 -p 3002 -c getTempA`.

## Configuration

The container expects to have the `vcontrold.xml` and `vito.xml` file passed to the `/config` folder. The `/config` folder should also contain the files to send your attributes through mqtt. For reference of these files look at this [GitHub REPO](https://github.com/michelde/openv-vcontrold-docker)

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

### Commands

The commands which should be read can be configured using the environment variable `COMMANDS`. If you want to read multiple commands, each command must be separated by a comma. As an example, my current `COMMANDS` variable looks like this:

```bash
COMMANDS=getTempWWObenIst,getTempWWsoll,getNeigungHK1,getTempVL,getTempRL,getPumpeStatusZirku,getBetriebArtHK1,getTempVListHK1,getTempRListHK1,getStatusVerdichter,getJAZ,getJAZHeiz,getJAZWW,getTempA,getPumpeStatusHK1
```

The program will then publish the value to the topic `$MQTTTOPIC/(COMMANDNAME)`.
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
      - /dev/serial/by-id/usb-FTDI_FT232R_USB_UART_AL1234-if00-port0:/dev/ttyUSB0
    environment:
      MQTTHOST: ${MQTTHOST}
      MQTTPORT: ${MQTTPORT}
      MQTTTOPIC: ${MQTTTOPIC}
      MQTTPASSWORD: ${MQTTPASSWORD}
      MQTTACTIVE: ${MQTTACTIVE}
      MQTTUSER: ${MQTTUSER}
      INTERVAL: ${INTERVAL}
      COMMANDS: ${COMMANDS}
    volumes:
      - ./config:/config

```

In order to pass the environment variables you can use the `.env` file and set the variables according to your needs.

If you want to use the `docker` command it would be e.g. `docker run -d --name='vcontrold-docker' --net='bridge' --privileged=true -e TZ="Europe/Berlin" -e 'MQTTACTIVE'='true' -e 'MQTTHOST'='mqtt-server.home' -e 'MQTTPORT'='1883' -e 'MQTTTOPIC'='vitocal' -e 'MQTTUSER'='mqtt_user' -e 'MQTTPASSWORD'='secret123' -e 'INTERVAL'='60' -v '.config/':'/config':'rw' --device=/dev/serial/by-id/usb-FTDI_FT232R_USB_UART_AL1234-if00-port0:/dev/ttyUSB0:rw 'michelmu/vcontrold-openv-mqtt'`

It also possible to set some values. This can be achieved using the topic `$MQTTTOPIC/commands`. A sample payload to set the water heating temperature would look like this: `setTempWWsoll 55`.
