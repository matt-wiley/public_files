#!/bin/sh
# FreeDNS Update Script (BusyBox compatible)
# This script detects your current public IP address and updates FreeDNS

set -euo pipefail

MOST_RECENT_IP_FILE="/tmp/ip0.txt"
PRIOR_IP_FILE="/tmp/ip1.txt"


# Function to log messages
log_message() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Get current public IP address (using multiple services for redundancy)
get_public_ip() {
  # Try multiple IP detection services in case one is down
  IP=$(wget -qO- https://api.ipify.org || wget -qO- https://ifconfig.me || wget -qO- https://icanhazip.com)

  if [ -z "$IP" ]; then
    log_message "ERROR: Could not determine public IP address"
    exit 1
  else
    log_message "Current public IP: $IP"
    echo "$IP" > $MOST_RECENT_IP_FILE
  fi
}
get_public_ip

# Check if the IP has changed since last update
CURRENT_IP=$(cat "$MOST_RECENT_IP_FILE")
if [ -f "$PRIOR_IP_FILE" ]; then
  LAST_IP=$(cat "$PRIOR_IP_FILE")
  if [ "$CURRENT_IP" = "$LAST_IP" ]; then
    log_message "IP unchanged ($CURRENT_IP). No update needed."
    exit 0
  fi
fi

# Save current IP for next run
cat "$MOST_RECENT_IP_FILE" > "$PRIOR_IP_FILE"

# Get the update URL from environment variable
FREEDNS_UPDATE_URL=${FREEDNS_UPDATE_URL:-""}

if [ -z "$FREEDNS_UPDATE_URL" ]; then
  log_message "ERROR: FREEDNS_UPDATE_URL environment variable not set"
  exit 1
fi

# Update FreeDNS
log_message "Updating FreeDNS with IP: $CURRENT_IP"
RESULT=$(wget -qO- "$FREEDNS_UPDATE_URL")

case "$RESULT" in
  *Updated* | *"has not changed"*)
    log_message "FreeDNS update successful: $RESULT"
    ;;
  *)
    log_message "FreeDNS update failed: $RESULT"
    ;;
esac

log_message "Update process completed"
exit 0
