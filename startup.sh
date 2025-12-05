#!/bin/bash
set -e  # Exit on error

# Wait for device to be ready
sleep 3

# Device configuration
USB_DEVICE=/dev/vitocal
LOCKFILE=/var/run/vclient.lock
LOCK_TIMEOUT=30  # Maximum seconds to wait for lock

echo "Device: ${USB_DEVICE}"

# Make device accessible
if [ -e "${USB_DEVICE}" ]; then
    chmod 777 "${USB_DEVICE}"
    echo "Device permissions set successfully"
else
    echo "ERROR: Device ${USB_DEVICE} not found!"
    echo "Available devices:"
    ls -l /dev/ | grep -E 'tty|usb' || true
    exit 1
fi

# Start vcontrold daemon
echo "Starting vcontrold daemon..."
vcontrold -x /config/vcontrold.xml -P /var/run/vcontrold.pid

status=$?
pid=$(pidof vcontrold)

if [ $status -ne 0 ]; then
    echo "ERROR: Failed to start vcontrold (exit code: $status)"
    exit 1
fi

if [ -z "$pid" ]; then
    echo "ERROR: vcontrold process not found"
    exit 1
fi

echo "vcontrold started successfully (PID: $pid)"

# Function to acquire lock with timeout
acquire_lock() {
    local wait_time=0
    while [ -e "${LOCKFILE}" ]; do
        if [ $wait_time -ge $LOCK_TIMEOUT ]; then
            echo "WARNING: Lock timeout reached, removing stale lockfile"
            rm -f "${LOCKFILE}"
            break
        fi
        sleep 1
        wait_time=$((wait_time + 1))
    done
    
    # Create lockfile with PID
    echo $$ > "${LOCKFILE}"
}

# Function to release lock
release_lock() {
    rm -f "${LOCKFILE}"
}

# Function to execute vclient with locking
vclient_with_lock() {
    local commands="$1"
    local output_file="$2"
    
    acquire_lock
    
    # Execute vclient command
    local result=0
    vclient -h 127.0.0.1:3002 -c "${commands}" -J -o "${output_file}" || result=$?
    
    release_lock
    
    return $result
}

# Export functions for use in mqtt_sub.sh
export -f acquire_lock
export -f release_lock
export -f vclient_with_lock
export LOCKFILE
export LOCK_TIMEOUT

# MQTT Mode
if [ "${MQTTACTIVE}" = "true" ]; then
    echo "MQTT: Active"
    echo "Update interval: ${INTERVAL} seconds"
    echo "Commands: ${COMMANDS}"
    echo "Lock mechanism: Enabled (timeout: ${LOCK_TIMEOUT}s)"
    
    # Validate required MQTT environment variables
    if [ -z "${MQTTHOST}" ] || [ -z "${MQTTPORT}" ] || [ -z "${MQTTTOPIC}" ]; then
        echo "ERROR: MQTT is active but required variables are missing"
        echo "Required: MQTTHOST, MQTTPORT, MQTTTOPIC"
        exit 1
    fi
    
    # Start MQTT subscription script in background if it exists
    if [ -f /config/mqtt_sub.sh ]; then
        echo "Starting MQTT subscription handler..."
        echo "NOTE: mqtt_sub.sh should use 'vclient_with_lock' function for safe access"
        /config/mqtt_sub.sh &
        MQTT_SUB_PID=$!
        echo "MQTT subscription handler started (PID: $MQTT_SUB_PID)"
    else
        echo "WARNING: /config/mqtt_sub.sh not found, command subscription disabled"
    fi
    
    # Main loop - read and publish values
    while sleep "${INTERVAL}"; do
        # Check if vcontrold is still running
        if [ ! -e /var/run/vcontrold.pid ]; then
            echo "ERROR: vcontrold.pid not found, daemon stopped unexpectedly"
            exit 1
        fi
        
        # Read values from vcontrold with locking
        if vclient_with_lock "${COMMANDS}" "result.json"; then
            # Publish to MQTT if script exists
            if [ -f /config/mqtt_publish.sh ]; then
                /config/mqtt_publish.sh
            else
                echo "WARNING: /config/mqtt_publish.sh not found, cannot publish to MQTT"
            fi
        else
            echo "WARNING: vclient command failed, retrying on next interval"
        fi
    done
else
    echo "MQTT: Inactive"
    echo "PID: $pid"
    echo "vcontrold is running in monitoring mode (no MQTT publishing)"
    
    # Monitoring loop - just keep container running and check daemon health
    while sleep 600; do
        if [ ! -e /var/run/vcontrold.pid ]; then
            echo "ERROR: vcontrold.pid not found, daemon stopped unexpectedly"
            exit 1
        fi
        
        # Optional: verify daemon is actually running
        if ! pidof vcontrold > /dev/null; then
            echo "ERROR: vcontrold process not running despite PID file existing"
            exit 1
        fi
    done
fi
