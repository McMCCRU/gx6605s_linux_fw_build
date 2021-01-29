#!/bin/sh

NTP_SERVER=""
SATIP_RESTART=""

if [ -f /home/gx/etc/config.conf ]; then
. /home/gx/etc/config.conf
fi

if [ ! -n "$NTP_SERVER" ]; then
	NTP_SERVER="ru.pool.ntp.org"
fi

if zyntp -rfl -t 5 -c 12 $NTP_SERVER; then
	if [ -f /etc/rcS.d/S98minisatip ] && [ ! -f /var/minisatip_time.lock ]; then
		/etc/rcS.d/S98minisatip restart $SATIP_RESTART
		touch /var/minisatip_time.lock
	fi
	super sched ntp -q -d 3600 /bin/ntp.sh
else
	super sched ntp -q -d 60 /bin/ntp.sh
fi
