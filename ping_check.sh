#!/bin/bash

# Telegram bot information
BOT_TOKEN=''
CHAT_ID=''
TIME=`date`
# List of IP addresses to ping
IP_LIST=(
    '123.456.789.123 NAME ICMP'
    '123.456.789.123 NAME ICMP'
)

# Associative array to track ping failure status for each IP
declare -A ping_failed

# Initialize ping_failed array
for ip_info in "${IP_LIST[@]}"; do
    IP=$(echo "$ip_info" | awk '{print $1}')
    ping_failed["$IP"]=false
done

# Function to send a message to Telegram
send_telegram_message() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d chat_id="${CHAT_ID}" \
        -d text="${message}"
}

# Function to check ping for each IP
check_ping() {
    for ip_info in "${IP_LIST[@]}"; do
        IP=$(echo "$ip_info" | awk '{print $1}')
        NAME=$(echo "$ip_info" | awk '{print $2}')
        PORT=$(echo "$ip_info" | awk '{print $3}')

        # Ping the IP address
        if ping -c 1 -W 1 "$IP" > /dev/null; then
            # If ping is successful and was previously failed, send success message
            if [ "${ping_failed["$IP"]}" = true ]; then
                TIME=`date`
                send_telegram_message "✅ [ $NAME ] [ $IP ] CONNECTED at $TIME !"
                ping_failed["$IP"]=false
            fi
        else
            # If ping fails, send failure message and update ping_failed status
            TIME=`date`
            send_telegram_message "⛔️ [ $NAME ] [ $IP ] DISCONNECTED at $TIME !"
            ping_failed["$IP"]=true
        fi
    done
}

# Function to send ping success message every 60 minutes
send_ping_success_message() {
    local ping_success=false
    TIME=`date`
    local message="🟢 Ping to the following hosts is successful at $TIME:"$'\n'
    for ip_info in "${IP_LIST[@]}"; do
        IP=$(echo "$ip_info" | awk '{print $1}')
        NAME=$(echo "$ip_info" | awk '{print $2}')
        PORT=$(echo "$ip_info" | awk '{print $3}')
        if ping -c 1 -W 1 "$IP" > /dev/null; then
            message+="[ $NAME ] [ $IP ]"$'\n'
            ping_success=true
        fi
    done
    if [ "$ping_success" = true ]; then
        send_telegram_message "$message"
    fi
}

# Continuously check ping every 10 seconds
while true; do
    check_ping
    # Send ping success message every 60 minutes
    if [ "$(date +'%M')" == "00" ]; then
        send_ping_success_message
        sleep 60
    fi
    sleep 10
done
