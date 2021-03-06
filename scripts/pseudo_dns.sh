#!/bin/bash
## Pushes and pulls the IP address of the raspberry pi server to the uchicago
## linux cluster so it can be re-obtained in case it ever changes.

USAGE="$0 <push | pull | check>\

  push: publishes the local and external IP addresses of the source computer to UChicago's linux computers. This should only be run from the server.
  pull: prints the external IP address of the pi server which is read from UChicago's linux computers.
  check: matches the external IP address stored at UChicago against the local entry in /etc/hosts. If they disagree, we need to update our table."

UCHI_SERVER="linux.cs.uchicago.edu"
EXT_IP_FILE="SJB_PI_IP"
LOCAL_IP_FILE="SJB_PI_IP_LOCAL"
PI_HOSTNAME="sjb-pi-ext"

if [[ "$#" -ne "1" ]]; then
  echo "Bad usage"
  echo "Usage: $USAGE"
  exit 1
fi

pull_ext() {
  ssh -o "StrictHostKeyChecking no" "$UCHI_SERVER" "cat $EXT_IP_FILE"
}

if [[ "$1" == "push" ]]; then
  # Get the local and external IP addresses.
  ip=$(ifconfig | grep 'inet 192' | sed -E 's/.*inet ([0-9\.]*) .*/\1/g')
  ext_ip=$(curl ipinfo.io/ip)

  if [[ "$?" -ne "0" ]]; then
    echo "Something went wrong with obtaining the ext ip via curl" > /dev/stderr
    exit 1
  fi

  # Publish them to UChicago's server.
  echo "$ip" | ssh -o "StrictHostKeyChecking no" "$UCHI_SERVER" 'cat > '"$LOCAL_IP_FILE"
  echo "$ext_ip" | ssh -o "StrictHostKeyChecking no" "$UCHI_SERVER" 'cat > '"$EXT_IP_FILE"

  exit 0

elif [[ "$1" == "pull" ]]; then

  ext_ip=$(pull_ext)
  echo "$ext_ip"
  exit 0

elif [[ "$1" == "check" ]]; then

  # Read from host table.
  saved_ip=$(gethostip "$PI_HOSTNAME" | sed -E 's/.* ([0-9\.]{7,15}) .*/\1/g')
  ext_ip=$(pull_ext)

  if [[ ! "$ext_ip" == "$saved_ip" ]]; then
    echo "WARNING: the published ip and saved ip of host $PI_HOSTNAME did not match!" >> /dev/stderr
    echo "You should update your /etc/hosts table" >> /dev/stderr
    exit 1
  fi
  exit 0

else 
  echo "Bad usage: Unrecognized command '$1'"
  echo "Usage: $USAGE"
  exit 1
fi







