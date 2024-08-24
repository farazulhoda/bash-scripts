#!/bin/bash

# Detect the active network interface automatically
INTERFACE=$(ip route | grep default | awk '{print $5}')

# Check if necessary tools are installed
for tool in vnstat tcpdump; do
    if ! command -v $tool &> /dev/null; then
        echo "$tool is not installed. Installing..."
        sudo apt-get install -y $tool || sudo yum install -y $tool || sudo dnf install -y $tool || sudo pacman -S --noconfirm $tool
    fi
done

# Function to clean up processes on exit
cleanup() {
    echo "Cleaning up..."
    killall tcpdump vnstat
    exit 0
}

# Trap the SIGINT (Ctrl+C) signal to clean up properly
trap cleanup SIGINT

# Start tcpdump in the background to monitor packets
sudo tcpdump -i $INTERFACE -w /dev/null &

# Start vnstat in live mode in the background
vnstat -i $INTERFACE --live 1 > /tmp/vnstat_output &

# Live updating display similar to htop
while true; do
    clear

    # Fetch network speed data from vnstat output
    RX=$(grep "rx" /tmp/vnstat_output | tail -n 1 | awk '{print $2}')
    TX=$(grep "tx" /tmp/vnstat_output | tail -n 1 | awk '{print $2}')
    
    # Fetch packet count from tcpdump (simulated)
    PKTS=$(sudo tcpdump -i $INTERFACE -c 1 2>&1 | grep -oP '\d+ packets captured')

    # Display a dashboard
    echo "┌───────────────────────────────────────────────────────────────────┐"
    echo "│                         Network Monitor (live)                    │"
    echo "├───────────────────────────────────────────────────────────────────┤"
    echo "│ Interface: $INTERFACE                                              │"
    echo "├───────────────────────────────────────────────────────────────────┤"
    echo "│ Downlink Speed (kbps): $RX                                         │"
    echo "│ Uplink Speed (kbps):   $TX                                         │"
    echo "│ Packets Captured:      $PKTS                                       │"
    echo "└───────────────────────────────────────────────────────────────────┘"
    
    sleep 1
done
