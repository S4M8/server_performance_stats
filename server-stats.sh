#! /bin/sh

# Server Performance Stats
# Purpose: Script should be able to analyse basic server performance at a glance.

# Sever Uptime
echo "==SYSTEM STATUS=="
uptime_raw=$(uptime)
# Extract uptime portion (everything before load average)
uptime_part=$(echo "$uptime_raw" | sed 's/,.*load average.*//')
# Extract load average portion
load_part=$(echo "$uptime_raw" | sed 's/.*load average: //')

echo "System uptime: $uptime_part"
echo "Load averages (1m, 5m, 15m): $load_part"

# User Information
echo ""
echo "==LOGGED ON USERS=="
who
unique_users=$(who | cut -d' ' -f1 | sort -u | wc -l)
echo "Total unique users logged in: $unique_users"

echo ""
echo "=== RECENT FAILED LOGIN ATTEMPTS ==="
if [ -r /var/log/messages ]; then
  echo "Checking system messages for failed attempts:"
  grep -i "fail" /var/log/messages 2>/dev/null | tail -5 || echo "No recent failed attempts found"
fi

if [ -r /var/log/auth.log ]; then
  echo "Checking auth log:"
  grep "Failed" /var/log/auth.log 2>/dev/null | tail -5 || echo "No failed attempts in auth.log"
elif [ -r /var/log/secure ]; then
  echo "Checking secure log:"
  grep "fail" /var/log/secure 2>/dev/null | tail -5 || echo "No failed attempts in secure log"
fi

echo ""
echo "=== SYSTEM RESOURCES ==="

# CPU information
number_of_cores=$(grep -c "^processor" /proc/cpuinfo 2>/dev/null || echo "1")
total_cpu=$(ps -eo pcpu | awk 'NR>1 {sum+=$1} END {print (sum ? sum : 0)}')
if [ "$number_of_cores" != "unknown" ] && [ "$number_of_cores" -gt 0 ]; then
  average_per_core=$(awk -v total="$total_cpu" -v cores="$number_of_cores" 'BEGIN {printf "%.2f", total/cores}')
else
  average_per_core="0.00"
fi
echo "Number of CPU cores: $number_of_cores"
echo "Total CPU usage: ${total_cpu}%"
echo "Average CPU usage per core: ${average_per_core}%"

# Memory usage
if [ -r /proc/meminfo ]; then
  mem_total=$(grep "^MemTotal:" /proc/meminfo | awk '{print $2}')
  mem_free=$(grep "^MemFree:" /proc/meminfo | awk '{print $2}')
  mem_available=$(grep "^MemAvailable:" /proc/meminfo | awk '{print $2}')

  if [ -n "$mem_total" ] && [ -n "$mem_available" ]; then
    mem_used=$((mem_total - mem_available))
    mem_percent=$(awk "BEGIN {printf \"%.2f\", ($mem_used/$mem_total)*100}")
    mem_total_mb=$((mem_total / 1024))
    mem_used_mb=$((mem_used / 1024))
    echo "Memory Usage: ${mem_used_mb}/${mem_total_mb}MB (${mem_percent}%)"
  fi
fi

# Disk usage
echo "Disk Usage:"
df / | awk 'NR==2{print "Root filesystem: " $3 "/" $2 " (" $5 " used)"}'

# Process information
echo ""
echo "Top processes by CPU:"
ps -eo pid,comm,pcpu,pmem | sort -k3 -nr | head -6

echo ""
echo "Top processes by memory:"
ps -eo pid,comm,pcpu,pmem | sort -k4 -nr | head -6

# OS information
echo ""
echo "=== SYSTEM INFORMATION ==="
if [ -r /etc/os-release ]; then
  grep -E '^(NAME|VERSION)=' /etc/os-release | sed 's/.*=//' | sed 's/"//g'
elif [ -r /etc/release ]; then
  cat /etc/release
elif [ -r /etc/version ]; then
  cat /etc/version
else
  uname -sr
fi
