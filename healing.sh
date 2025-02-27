#!/bin/bash

# Lock file
LOCK_FILE="$(dirname "${BASH_SOURCE[0]}")/monitoring_script.lock"

# print time & date
println() {
    printf "%s %s\n" "$(date)" "$1"
}

# Check if lock file exists
if [ -e "$LOCK_FILE" ]; then
    println "Script is already running. Exiting."
    exit 1
fi

# Create lock file
touch "$LOCK_FILE"

# Function to remove lock file
cleanup() {
    println "Cleaning up and terminating monitoring script..."
    # Remove lock file
    rm -f "$LOCK_FILE"
    exit 0
}

# Trap signals for cleanup
trap 'cleanup' EXIT SIGINT SIGTERM

# Define parameters
CURL_INTERVAL=5
NUM_FAILURES_SOFT_RESTART=5
NUM_FAILURES_FULL_RESTART=10
PROCESS_NAME="keycloak"
PORT_NUMBER=8080
START_SCRIPT_PATH="/ln/abc/startKc.sh"

# Define file paths
LOG_DIR="$(dirname "${BASH_SOURCE[0]}")/logs"
DATE=$(date +'%Y-%m-%d')
RESPONSE_FILE="$LOG_DIR/$DATE.json"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Function to save response to JSON file
save_response_to_json() {
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    local pid_monitoring_script=$$
    local pid_keycloak=$(ps -ef | grep "java.*$PROCESS_NAME" | grep "$PORT_NUMBER" | grep -v grep | awk '{print $2}')

    local response_code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$PORT_NUMBER")

    echo "{\"timestamp\": \"$timestamp\", \"pid_monitoring_script\": \"$pid_monitoring_script\", \"pid_keycloak\": \"$pid_keycloak\", \"response_code\": \"$response_code\"}" >> "$RESPONSE_FILE"
}

# Function to soft restart keycloak
soft_restart() {
    println "Initiating soft restart..."
    "$START_SCRIPT_PATH" &
}

# Function to full restart keycloak
full_restart() {
    println "Initiating full restart..."
    kill -15 "$(ps -ef | grep "java.*$PROCESS_NAME" | grep "$PORT_NUMBER" | grep -v grep | awk '{print $2}')"
    sleep 5
    "$START_SCRIPT_PATH" &
}

# Main function
main() {
    consecutive_failures_soft_restart=0
    consecutive_failures_full_restart=0

    # Main monitoring loop
    while true; do
        DATE=$(date +'%Y-%m-%d')
        RESPONSE_FILE="$LOG_DIR/$DATE.json"

        save_response_to_json

        if ! ps -ef | grep "java.*$PROCESS_NAME" | grep "$PORT_NUMBER" | grep -q -v grep; then
            soft_restart
            #consecutive_failures_soft_restart=0  # Reset consecutive failures for soft restart
            consecutive_failures_full_restart=0  # Reset consecutive failures for full restart
        else
            if [ "$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$PORT_NUMBER")" != "200" ]; then
                #((consecutive_failures_soft_restart++))
                ((consecutive_failures_full_restart++))
                println "Site is unreachable or not OK. Consecutive failures for full restart: $consecutive_failures_full_restart"
                #if [ $consecutive_failures_soft_restart -gt "$NUM_FAILURES_SOFT_RESTART" ]; then
                #    soft_restart
                #    consecutive_failures_soft_restart=0  # Reset consecutive failures for soft restart
                #fi
                if [ $consecutive_failures_full_restart -gt "$NUM_FAILURES_FULL_RESTART" ]; then
                    full_restart
                    consecutive_failures_full_restart=0  # Reset consecutive failures for full restart
                fi
            else
                consecutive_failures_soft_restart=0  # Reset consecutive failures for soft restart
                consecutive_failures_full_restart=0  # Reset consecutive failures for full restart
                println "Site is reachable and OK."
            fi
        fi

        sleep "$CURL_INTERVAL"
    done
}

Cron Function
# Run the main function
main
