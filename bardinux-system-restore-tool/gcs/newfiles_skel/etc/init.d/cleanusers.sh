#!/bin/sh

### BEGIN INIT INFO
# Provides:             cleanusers
# Required-Start:    	$syslog
# Required-Stop:		
# Default-Start:        2 3 4 5
# Default-Stop:         0 1 6
# Short-Description:    Remove inactive users
### END INIT INFO

. /lib/lsb/init-functions
. /etc/default/bsrt

[ ${INACTIVITY_LIMIT} ] || exit 0

INACTIVITY_LIMIT=$((${INACTIVITY_LIMIT} * 86400)) # In seconds

case "$1" in
	start)
		log_begin_msg "Cleaning old users..."
		for USERNAME in $(ls /home/ ${NOREMOVE_INACTIVE:+"-I ${NOREMOVE_INACTIVE}"}); do
			LASTLOGIN=$(finger ${USERNAME} | grep "Last login" | cut -d " " -f 3-7)
			TIMEAGO=$(($(date +%s) - $(date +%s -d "${LASTLOGIN}")))
			if [ ${TIMEAGO} -gt ${INACTIVITY_LIMIT} ] && grep -q "^${USERNAME}:" /etc/passwd; then
				if userdel -rf $USERNAME; then
					logger -t "cleanusers" "User ${USERNAME} deleted."
				else
					logger -t "cleanusers" "Impossible to delete user ${USERNAME}."
				fi
			else
				logger -t "cleanusers" "Any users to delete."
			fi
		done
		log_end_msg $?
		;;
	*)
		log_success_msg "Usage: cleanusers.sh {start}"
		;;
esac
