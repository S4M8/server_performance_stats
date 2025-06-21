#! /usr/bin/env bash

# Server Performance Stats
# Purpose: Script should be able to analyse basic server performance at a glance.

# Requirements:

# OS Version:
echo "OS Information"
cat /etc/os-release | grep -E '^(NAME|VERSION)=' /etc/os-release | awk -F= '{print $2}' | tr -d '"'

# Total CPU usage
number_of_cores=$(nproc)
total_cpu=$(ps -Ao pcpu | awk 'NR>1 {sum+=$1} END {print sum}')

average_per_core=$(awk -v total="$total_cpu" -v cores="$number_of_cores" 'BEGIN {print total/cores}')

echo "Total CPU usage: $total_cpu%"
echo "Number of CPU cores: $number_of_cores"
echo "Average CPU usage per core: $average_per_core%"

# Total memory usage
free -m | awk 'NR==2{printf "Memory Usage: %s/%sMB (%.2f%%)\n", $3, $2, $3*100/$2}'

# Total disk usage
df -h | awk 'NR==2{printf "Disk Usage: %s/%s (%s used)\n", $3, $2, $5}'

# Top 5 processes by CPU usage
echo "Top 5 processes by CPU"
ps -eo pid,cmd,%cpu,%mem --sort=-%cpu | head -n 6

# Top 5 processes by memory usage
echo "Top 5 processes by Memory"
ps -eo pid,cmd,%cpu,%mem --sort=-%mem | head -n 6

# Stretch Goals:
# OS version
# Uptime
# Load average
# Logged in users
# Failed login attempts
