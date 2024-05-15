#!/bin/bash

# Telegram bot information
BOT_TOKEN=''
CHAT_ID=''
TIME=`date`

# List of IP addresses and ports to check
CONNECTION_LIST=(
    '123.234.345.456 EDGE-ABC-01 80'
    '103.123.123.123 EDGE-ABC-01 443'
)

# Associative array to track connection failure status for each IP and port
declare -A connection_failed

# Initialize connection_failed array
for conn_info in "${CONNECTION_LIST[@]}"; do
    IP=$(echo "$conn_info" | awk '{print $1}')
    PORT=$(echo "$conn_info" | awk '{print $3}')
    connection_failed["$IP:$PORT"]=false
done

# Function to send a message to Telegram
send_telegram_message() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d chat_id="${CHAT_ID}" \
        -d text="${message}"
}

# Function to check connection for each IP and port
check_connection() {
    for conn_info in "${CONNECTION_LIST[@]}"; do
        IP=$(echo "$conn_info" | awk '{print $1}')
        NAME=$(echo "$conn_info" | awk '{print $2}')
        PORT=$(echo "$conn_info" | awk '{print $3}')

        # Check TCP connection to the IP and port
        if nc -z -w1 "$IP" "$PORT" >/dev/null 2>&1; then
            # If connection is successful and was previously failed, send success message
            if [ "${connection_failed["$IP:$PORT"]}" = true ]; then
                send_telegram_message "✅ CONNECTED TO [ $NAME ] [ $IP:$PORT ] at $TIME !"
                connection_failed["$IP:$PORT"]=false
            fi
        else
            # If connection fails, send failure message and update connection_failed status
            send_telegram_message "⛔️ DISCONNECTED TO [ $NAME ] [ $IP:$PORT ] DISCONNECTED at $TIME !"
            connection_failed["$IP:$PORT"]=true
        fi
    done
}

# Function to send connection success message every 60 minutes
send_connection_success_message() {
    local conn_success=false
    TIME=`date`
    local message="🟢 Connection to the following hosts and ports is successful at $TIME:"$'\n'
    for conn_info in "${CONNECTION_LIST[@]}"; do
        IP=$(echo "$conn_info" | awk '{print $1}')
        NAME=$(echo "$conn_info" | awk '{print $2}')
        PORT=$(echo "$conn_info" | awk '{print $3}')
        if nc -z -w1 "$IP" "$PORT" >/dev/null 2>&1; then
            message+="[ $NAME ] [ $IP ] [ $PORT ]"$'\n'
            conn_success=true
        fi
    done
    if [ "$conn_success" = true ]; then
        send_telegram_message "$message"
    fi
}

# Continuously check connection every 10 seconds
while true; do
    check_connection
    # Send connection success message every 60 minutes
    if [ "$(date +'%M')" == "00" ]; then
        send_connection_success_message
        sleep 60
    fi
    sleep 10
done
