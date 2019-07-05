##!/bin/bash
##########################
# v 2019.07.4
# Bodge script to clear and rebuild
#
# Add to Crontab to run as often as you need
##########################
# Configuration #
# IP address to monitor
monitor=100.124.70.254
# next hop gateway (applies to all routes)
vti=vti0
# Configuration end #

    execute=/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper
    recv=$(/bin/ping -c 2 -q -i 1 $monitor | grep received | cut -d, -f2 | awk '{print $1}')
# If no response
    if [ "$recv" -eq 0 ]; then
            logger "`basename "$monitor"` seems down now, routes will be re-applied"
            # Start command session and delete route
             $execute begin
              $execute delete protocols static interface-route $monitor/32
             $execute commit
            # now lets drop the route back in
             $execute set protocols static interface-route $monitor/32 next-hop-interface $vti
              $execute commit
             $execute end
        fi

## fix permission problem created by wrapper

chown -R root:vyattacfg /opt/vyatta/config/active
