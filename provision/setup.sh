#!/bin/bash

# Capture network variable:
NETWORK_BASE=$1
sudo -i

echo "Check eth1 ip config for netbase: $NETWORK_BASE"

if ip a show dev enp0s8 | grep -q "inet $NETWORK_BASE"; then
  echo "enp0s8 ip detected"
else
  echo "enp0s8 missing ip; restaring interface"
  ifdown eth1 && ifup enp0s8
fi
