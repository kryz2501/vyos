#!/bin/bash
##########################
# v 2019.07.4
# Bodge script to clear and rebuild
#
# Add to Crontab to run as often as you need
##########################


# Configuration #

# source interface
interface=<eth4>

# number of pings
count=3

# IP address to monitor
monitor=$1

# action to take when test fails should be add/remove
action=<add/remove>

# routes to add remove, space delimited <ip/CIDR>
routes=(<IP>/<CIDR> <IP>/<CIDR>)

# next hop gateway (applies to all routes)
gwaddress=<IP>

#interval between pings
interval=5

# Configuration end #

    if [ $action = "add" ]; then
      upaction=delete
      downaction=set
      upnexthop= 
      downnexthop="next-hop $gwaddress"
    else
      upaction=set
      downaction=delete
      downnexthop=         
      upnexthop="next-hop $gwaddress"

    fi
     flag=/tmp/`basename "$0"`-target.up
     execute=/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper

    recv=$(/bin/ping -c $count -I $interface -q -i $interval $monitor | grep received | cut -d, -f2 | awk '{print $1}')


# If no response
    if [ "$recv" -eq 0 ]; then
        if [ -f $flag ]; then
            logger "`basename "$0"` target seems down now, reoutes will be re-applied" $downaction
            rm -f $flag
	    $execute begin
             for route in "${routes[@]}"
              do
                $execute  $downaction protocols static route $route $downnexthop
              done
                 $execute commit
                 $execute end
            /usr/sbin/conntrack -F > /dev/null 2>&1
            /usr/sbin/conntrack -F expect > /dev/null 2>&1
        fi
    else
# when there is a response and device was previously down
        if [ ! -f $flag ]; then
            logger "`basename "$0"` target seems up now, failover route have been" $upaction
            touch $flag
            $execute begin
             for route in "${routes[@]}"
              do
                $execute  $upaction protocols static route $route $upnexthop
              done
		$execute commit
		 $execute end
            /usr/sbin/conntrack -F > /dev/null 2>&1
            /usr/sbin/conntrack -F > /dev/null 2>&1
        fi
    fi

## fix permission problem created by wrapper

chown -R root:vyattacfg /opt/vyatta/config/active


