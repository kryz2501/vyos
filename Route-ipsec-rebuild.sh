#!/bin/bash
##########################
# v 2019.07.4
# Bodge script to clear and rebuild
#
# Add to Crontab to run as often as you need
##########################


# Configuration #

# number of pings
count=3

# IP address to monitor
monitor=<IP>

# next hop gateway (applies to all routes)
vti=<vti#>

#interval between pings
interval=5

# Configuration end #
    execute=/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper

    recv=$(/bin/ping -c $count -q -i $interval $monitor | grep received | cut -d, -f2 | awk '{print $1}')


# If no response
    if [ "$recv" -eq 0 ]; then
            logger "`basename "$0"` target seems down now, routes will be re-applied" $downaction
            rm -f $flag
	    # Start command session and delete route
	    $execute begin
            $execute delete protocols static interface-route $monitor/32
            $execute commit
	    # now lets drop the route back in
	    $execute delete protocols static interface-route $monitor/32 next-hop-interface $vti
            $execute commit
            $execute end
        fi

## fix permission problem created by wrapper

chown -R root:vyattacfg /opt/vyatta/config/active


