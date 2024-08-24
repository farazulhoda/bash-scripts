#!/bin/bash

# Detect the active network interface automatically
INTERFACE=$(ip route | grep default | awk '{print $5}')

# Check if the necessary tools are installed
for tool in vnstat gnuplot tcpdump; do
    if ! command -v $tool &> /dev/null; then
        echo "$tool is not installed. Installing..."
        sudo apt-get install -y $tool || sudo yum install -y $tool || sudo dnf install -y $tool || sudo pacman -S --noconfirm $tool
    fi
done

# Temporary file for gnuplot data
OUTPUT="/tmp/network_speed.dat"

# Function to clean up processes on exit
cleanup() {
    echo "Cleaning up..."
    rm -f $OUTPUT
    killall vnstat
    killall tcpdump
    exit 0
}

# Trap the SIGINT (Ctrl+C) signal to clean up properly
trap cleanup SIGINT

# Start tcpdump to capture packets (requires root privileges)
sudo tcpdump -i $INTERFACE -w packets.pcap &

# Start vnstat in live mode in the background
vnstat -i $INTERFACE --live 1 > $OUTPUT &

# Start the live graph using gnuplot in an infinite loop
while true; do
    gnuplot -persist <<-EOFMarker
        set title "Live Network Speed (kbps) - $INTERFACE"
        set xlabel "Time (seconds)"
        set ylabel "Speed (kbps)"
        set grid
        set autoscale
        set term wxt
        plot "$OUTPUT" using 1:2 with lines title "Download", \
             "$OUTPUT" using 1:3 with lines title "Upload"
        pause 1
    EOFMarker

    # Clear the data file to avoid unnecessary growth
    > $OUTPUT
done