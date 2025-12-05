# openv-vcontrold-docker

[![Docker Build](https://github.com/michelde/openv-vcontrold-docker/actions/workflows/docker-build.yml/badge.svg)](https://github.com/michelde/openv-vcontrold-docker/actions/workflows/docker-build.yml)
[![Docker Image](https://img.shields.io/docker/pulls/michelmu/vcontrold-openv.svg)](https://hub.docker.com/r/michelmu/vcontrold-openv)
[![License](https://img.shields.io/github/license/michelde/openv-vcontrold-docker.svg)](LICENSE)

A Docker container for Viessmann Optolink Control based on the OpenV library. This container runs the `vcontrold` daemon to connect to Viessmann heating systems via the Optolink interface and publishes values to an MQTT broker.

## Features

- 🔧 **Easy Setup**: Pre-configured container with vcontrold daemon
- 📡 **MQTT Integration**: Automatic publishing of heating system values
- 🔄 **Bidirectional Control**: Read values and send commands via MQTT
- 🏗️ **Multi-Architecture**: Supports AMD64, ARM64, and ARMv7 platforms
- 🐳 **Optimized**: Multi-stage Docker build for minimal image size
- ✅ **Health Checks**: Built-in monitoring for container health

## Supported Architectures

This image supports multiple architectures:

- `linux/amd64` - 64-bit x86 (Intel/AMD)
- `linux/arm64` - 64-bit ARM (Raspberry Pi 4, Apple Silicon, etc.)
- `linux/arm/v7` - 32-bit ARM (Raspberry Pi 2/3, etc.)

## Hardware Requirements

### Optolink Adapter

You need an Optolink adapter connected to your host system. The adapter connects to your Viessmann heating system's optical interface.

**Recommended adapters:**
- USB-based Optolink adapters with FTDI chip
- Any adapter compatible with the OpenV vcontrold software

**Important:** Use the device's serial ID (e.g., `/dev/serial/by-id/usb-FTDI_...`) instead of `/dev/ttyUSB0` to ensure consistent device mapping across reboots.

### Supported Heating Systems

Compatible with Viessmann heating systems that support the Optolink interface, including:
- Vitodens series
- Vitocal series (heat pumps)
- Vitotronic controllers
- And many others

## Software Requirements

### MQTT Broker

An MQTT broker is required to receive the heating system values. Popular options:
- [Eclipse Mosquitto](https://mosquitto.org/)
- [HiveMQ](https://www.hivemq.com/)
- Home Assistant's built-in MQTT broker

### Optional: Testing Without MQTT

Set `MQTTACTIVE=false` to test the vcontrold daemon without MQTT. You can then:
1. Access the container: `docker exec -it vcontrold bash`
2. Test commands: `vclient -h 127.0.0.1 -p 3002 -c getTempA`

## Quick Start

### 1. Prepare Configuration Files

Create a `config` directory with the following files:
- `vcontrold.xml` - Main vcontrold configuration
- `vito.xml` - Device-specific commands for your heating system
- `mqtt_publish.sh` - Script to publish values to MQTT
- `mqtt_sub.sh` - Script to subscribe to MQTT commands

Example configuration files are included in this repository.

### 2. Create docker-compose.yml

```yaml
version: '3.8'

services:
  vcontrold:
    image: michelmu/vcontrold-openv:latest
    container_name: vcontrold
    restart: unless-stopped
    devices:
      # Use serial-by-id for stable device mapping
      - /dev/serial/by-id/usb-FTDI_FT232R_USB_UART_AL00AKZQ-if00-port0:/dev/vitocal:rwm
      # Alternative for Synology or systems without serial-by-id:
      # - /dev/ttyUSB0:/dev/vitocal:rwm
    environment:
      MQTTACTIVE: "true"
      MQTTHOST: "mqtt-broker.local"
      MQTTPORT: "1883"
      MQTTTOPIC: "home/heating/"
      MQTTUSER: "mqtt_user"
      MQTTPASSWORD: "mqtt_password"
      INTERVAL: "60"
      COMMANDS: "getTempA,getTempWWist,getTempVL,getTempRL"
    volumes:
      - ./config:/config:ro
    healthcheck:
      test: ["CMD", "pidof", "vcontrold"]
      interval: 60s
      timeout: 10s
      retries: 3
      start_period: 30s
```

### 3. Create .env File (Optional)

Create a `.env` file for easier configuration management:

```bash
MQTTACTIVE=true
MQTTHOST=192.168.1.100
MQTTPORT=1883
MQTTTOPIC=home/heating/
MQTTUSER=your_mqtt_user
MQTTPASSWORD=your_mqtt_password
INTERVAL=60
COMMANDS=getTempA,getTempWWist,getTempVL,getTempRL
```

Then reference it in docker-compose.yml:

```yaml
environment:
  MQTTHOST: ${MQTTHOST}
  MQTTPORT: ${MQTTPORT}
  # ... etc
```

### 4. Start the Container

```bash
docker-compose up -d
```

### 5. Verify Operation

```bash
# Check container logs
docker-compose logs -f vcontrold

# Check container health
docker ps

# Test vclient manually
docker exec -it vcontrold vclient -h 127.0.0.1 -p 3002 -c getTempA
```

## Configuration

### Environment Variables

| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `MQTTACTIVE` | Enable/disable MQTT publishing | `true` or `false` | Yes |
| `MQTTHOST` | MQTT broker hostname or IP | `192.168.1.100` or `mqtt.home` | If MQTT active |
| `MQTTPORT` | MQTT broker port | `1883` | If MQTT active |
| `MQTTTOPIC` | MQTT topic prefix (trailing slash recommended) | `home/heating/` | If MQTT active |
| `MQTTUSER` | MQTT username (if authentication enabled) | `mqtt_user` | Optional |
| `MQTTPASSWORD` | MQTT password (if authentication enabled) | `secret123` | Optional |
| `INTERVAL` | Read interval in seconds | `60` | Yes |
| `COMMANDS` | Comma-separated list of commands to read | `getTempA,getTempWWist` | Yes |

### Available Commands

The available commands depend on your heating system and the `vito.xml` configuration. Common commands include:

**Temperature readings:**
- `getTempA` - Outside temperature
- `getTempWWist` - Hot water actual temperature
- `getTempWWsoll` - Hot water setpoint temperature
- `getTempVL` - Flow temperature
- `getTempRL` - Return temperature
- `getTempVListHK1` - Flow temperature setpoint heating circuit 1
- `getTempRListHK1` - Return temperature setpoint heating circuit 1

**Status information:**
- `getBetriebArtHK1` - Operating mode heating circuit 1
- `getStatusVerdichter` - Compressor status
- `getPumpeStatusHK1` - Circulation pump status heating circuit 1
- `getPumpeStatusZirku` - Circulation pump status

**Performance data (heat pumps):**
- `getJAZ` - Seasonal performance factor (SPF)
- `getJAZHeiz` - SPF for heating
- `getJAZWW` - SPF for hot water

**Configuration:**
- `getNeigungHK1` - Heating curve slope heating circuit 1

### Example Command Configuration

```bash
COMMANDS=getTempA,getTempWWist,getTempWWsoll,getTempVL,getTempRL,getBetriebArtHK1,getStatusVerdichter,getJAZ
```

### MQTT Topics

**Reading values:** The container publishes values to:
```
{MQTTTOPIC}{COMMAND_NAME}
```

Example: If `MQTTTOPIC=home/heating/` and command is `getTempA`, values are published to `home/heating/getTempA`

**Setting values:** Send commands to:
```
{MQTTTOPIC}commands
```

Example payload to set hot water temperature:
```
setTempWWsoll 55
```

### vcontrold Configuration

Edit `config/vcontrold.xml` to match your setup:
- Device path (usually `/dev/vitocal`)
- Network settings
- Protocol type

Edit `config/vito.xml` to match your specific Viessmann heating system model and available commands.

## Building from Source

### Standard Build

```bash
# Clone the repository
git clone https://github.com/michelde/openv-vcontrold-docker.git
cd openv-vcontrold-docker

# Build the image
docker build -t vcontrold-openv .
```

### Multi-Architecture Build

```bash
# Create and use a new builder
docker buildx create --name multiarch --use

# Build for multiple platforms
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  --tag michelmu/vcontrold-openv:latest \
  --push .
```

### Local Multi-Arch Build (without pushing)

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  --tag vcontrold-openv:local \
  --load .
```

## Troubleshooting

### Container doesn't start

1. **Check device permissions:**
   ```bash
   ls -l /dev/serial/by-id/
   # or
   ls -l /dev/ttyUSB*
   ```

2. **Verify device mapping in docker-compose.yml**

3. **Check container logs:**
   ```bash
   docker-compose logs vcontrold
   ```

### No values published to MQTT

1. **Verify MQTT broker is accessible:**
   ```bash
   docker exec -it vcontrold ping mqtt-broker-hostname
   ```

2. **Test MQTT connection manually:**
   ```bash
   docker exec -it vcontrold mosquitto_pub -h mqtt-broker -p 1883 -t test -m "hello"
   ```

3. **Check if vcontrold is running:**
   ```bash
   docker exec -it vcontrold pidof vcontrold
   ```

4. **Test vclient directly:**
   ```bash
   docker exec -it vcontrold vclient -h 127.0.0.1 -p 3002 -c getTempA
   ```

### Commands return errors

1. **Verify commands are valid for your heating system** - check `vito.xml`
2. **Ensure vcontrold.xml matches your device** - protocol, device path, etc.
3. **Check Optolink adapter connection** - LED indicators should be active

### Device name changes on reboot

Use serial-by-id instead of `/dev/ttyUSB0`:

```bash
# Find your device's serial ID
ls -l /dev/serial/by-id/

# Use in docker-compose.yml
devices:
  - /dev/serial/by-id/usb-FTDI_FT232R_USB_UART_AL00AKZQ-if00-port0:/dev/vitocal:rwm
```

## Advanced Usage

### Running on Synology NAS

Synology systems may not have `/dev/serial/by-id/`. Use:

```yaml
devices:
  - /dev/ttyUSB0:/dev/vitocal:rwm
  - /dev/bus/usb:/dev/bus/usb:rwm
```

### Using with Home Assistant

1. Install and configure MQTT integration in Home Assistant
2. Values will automatically appear as sensors
3. Add to `configuration.yaml`:

```yaml
sensor:
  - platform: mqtt
    name: "Outside Temperature"
    state_topic: "home/heating/getTempA"
    unit_of_measurement: "°C"
    
  - platform: mqtt
    name: "Hot Water Temperature"
    state_topic: "home/heating/getTempWWist"
    unit_of_measurement: "°C"
```

### Custom Scripts

You can customize the MQTT scripts in the `config` directory:
- `mqtt_publish.sh` - Modify how values are published
- `mqtt_sub.sh` - Add custom command handling

**Important: Understanding the Lock Mechanism**

To prevent race conditions when reading/writing to the heating system, the container implements a lock mechanism.

**Which scripts need the lock?**

| Script | Needs Lock? | Reason |
|--------|-------------|--------|
| `mqtt_sub.sh` | ✅ YES | Calls `vclient` to execute commands |
| `mqtt_publish.sh` | ❌ NO | Only reads `result.json`, no vclient access |
| Custom scripts | ✅ YES | If they call `vclient` directly |

**Execution flow:**
```
Main Loop (periodic reading):
  1. Acquire lock
  2. vclient reads values → result.json
  3. Release lock
  4. mqtt_publish.sh publishes result.json (NO lock needed)

MQTT Command (via mqtt_sub.sh):
  1. Acquire lock (waits if main loop is reading)
  2. vclient executes command
  3. Release lock
```

**How to use in custom scripts:**

```bash
# Example: Safe vclient usage in mqtt_sub.sh or custom scripts
if vclient_with_lock "getTempA" "result.json"; then
    # Process result
    result=$(jq -r '.[]' result.json)
    echo "Temperature: ${result}"
else
    echo "ERROR: Command failed"
fi
```

**Lock mechanism features:**
- Prevents simultaneous access to vcontrold
- Configurable timeout (default: 30 seconds)
- Automatically cleans up stale locks
- Used automatically by the periodic reading loop
- **Must be used** in `mqtt_sub.sh` for command handling
- **Not needed** in `mqtt_publish.sh` (only reads files)

**Available exported functions:**
- `vclient_with_lock <commands> <output_file>` - Execute vclient with automatic locking
- `acquire_lock` - Manually acquire lock (advanced usage)
- `release_lock` - Manually release lock (advanced usage)

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## References

- [OpenV Project](https://github.com/openv/vcontrold)
- [Viessmann Optolink Documentation](https://github.com/openv/openv/wiki)
- [MQTT Protocol](https://mqtt.org/)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/michelde/openv-vcontrold-docker/issues)
- **Discussions**: [GitHub Discussions](https://github.com/michelde/openv-vcontrold-docker/discussions)

## Acknowledgments

- OpenV project for the vcontrold software
- The Viessmann community for protocol documentation
- All contributors to this project
