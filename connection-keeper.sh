#!/bin/bash

### SETTINGS BEGIN ###

# Adding folder with "sakis3gz" to PATH variable
PATH=$PATH:/home/pi/connection-keeper

# Set this as default gateway for wired connection
# Run "route | grep default" to learn default gateway
# while connected to wired network
primary_gw="192.168.0.1"

# Wired network interface name
ethernet="eth0"

# Settings for connection to internet with "sakis3g"
sakis3g_options="APN=internet.nw USBDRIVER=option MODEM=12d1:1001"

# Connection state check period in seconds
check_delay=60

### SETTINGS END ###

# DON'T CHANGE
ping_address="8.8.8.8"

ping_command="ping -c 1 -W 1 $ping_address |& \
              grep -E \"(unreachable|100\%\ packet\ loss)\" &> /dev/null"

route_via_gw="ip route add $ping_address via $primary_gw &> /dev/null"

function change_to_primary {
    sakis3gz disconnect
    # This is required to get name resolution working properly
    ifdown $ethernet
    ifup $ethernet
}

function change_to_secondary {
    sakis3gz connect --pppd $sakis3g_options
}

function connection_checker {
    # First we check internet connection
    if eval $ping_command ;then
        # If we don't have internet
        if [ -e /tmp/wan_backup ] ;then
            # If we are using backup right now we try to change to primary connection
            echo "Secondary connection was lost, trying to switch back to primary"
            change_to_primary
            rm /tmp/wan_backup
        else
            # Else we change to wan backup.
            echo "Primary connection was lost, switching to backup"
            change_to_secondary
            touch /tmp/wan_backup
        fi
        else
            echo -n "Current connection"
            if [ -e /tmp/wan_backup ] ;then
                echo -n " [backup] "
            else
                echo -n " [primary] "
            fi
        echo "is alive"
    fi

    # If we are using wan backup right now we check if primary connection works
    if [ -e /tmp/wan_backup ] ;then
        if eval $route_via_gw ;then
            if eval $ping_command ;then
                # Doesn't work
                echo "Keep using backup"
                ip route del $ping_address via $primary_gw &> /dev/null
            else # It works so we change active connection
                echo "Primary connection is alive, switching to it"
                change_to_primary
                rm /tmp/wan_backup
            fi
        else
            echo "Keep using backup 2"
            ip route del $ping_address via $primary_gw &> /dev/null
        fi
    fi
}

while true
do
    echo "Run connection keeper..."
    connection_checker
    sleep $check_delay
done
