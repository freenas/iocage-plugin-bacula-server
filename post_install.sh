#!/bin/sh

# Enable the service
sysrc -f /etc/rc.conf bacula-server_enable="YES"

# Start the service
service bacula-server start 2>/dev/null
