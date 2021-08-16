#!/bin/bash

# Check if /config/flaresolverr exists, if not make the directory
if [[ ! -e /config/flaresolverr ]]; then
	mkdir -p /config/flaresolverr
fi

# Set the correct rights accordingly to the PUID and PGID on /config/flaresolverr
chown -R ${PUID}:${PGID} /config/flaresolverr

# Set the rights on the /blackhole folder
chown -R ${PUID}:${PGID} /blackhole

# Check if the PGID exists, if not create the group with the name 'flaresolverr'
grep $"${PGID}:" /etc/group > /dev/null 2>&1
if [ $? -eq 0 ]; then
	echo "[INFO] A group with PGID $PGID already exists in /etc/group, nothing to do." | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[INFO] A group with PGID $PGID does not exist, adding a group called 'flaresolverr' with PGID $PGID" | ts '%Y-%m-%d %H:%M:%.S'
	groupadd -g $PGID flaresolverr
fi

# Check if the PUID exists, if not create the user with the name 'flaresolverr', with the correct group
grep $"${PUID}:" /etc/passwd > /dev/null 2>&1
if [ $? -eq 0 ]; then
	echo "[INFO] An user with PUID $PUID already exists in /etc/passwd, nothing to do." | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[INFO] An user with PUID $PUID does not exist, adding an user called 'flaresolverr user' with PUID $PUID" | ts '%Y-%m-%d %H:%M:%.S'
	useradd -c "flaresolverr user" -g $PGID -u $PUID flaresolverr
fi

# Set the umask
if [[ ! -z "${UMASK}" ]]; then
	echo "[INFO] UMASK defined as '${UMASK}'" | ts '%Y-%m-%d %H:%M:%.S'
	export UMASK=$(echo "${UMASK}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
else
	echo "[WARNING] UMASK not defined (via -e UMASK), defaulting to '002'" | ts '%Y-%m-%d %H:%M:%.S'
	export UMASK="002"
fi

# Start flaresolverr
echo "[INFO] Starting flaresolverr daemon..." | ts '%Y-%m-%d %H:%M:%.S'
/bin/bash /etc/flaresolverr/flaresolverr.init start

# Wait a second for it to start up and get the process id
sleep 1
flaresolverrpid=$(pgrep -o -x flaresolverr) 
echo "[INFO] flaresolverr PID: $flaresolverrpid" | ts '%Y-%m-%d %H:%M:%.S'

# If the process exists, make sure that the log file has the proper rights and start the health check
if [ -e /proc/$flaresolverrpid ]; then
	if [[ -e /config/flaresolverr/Logs/log.txt ]]; then
		chmod 775 /config/flaresolverr/Logs/log.txt
	fi
	
	# Set some variables that are used
	HOST=${HEALTH_CHECK_HOST}
	DEFAULT_HOST="one.one.one.one"
	INTERVAL=${HEALTH_CHECK_INTERVAL}
	DEFAULT_INTERVAL=300
	
	# If host is zero (not set) default it to the DEFAULT_HOST variable
	if [[ -z "${HOST}" ]]; then
		echo "[INFO] HEALTH_CHECK_HOST is not set. For now using default host ${DEFAULT_HOST}" | ts '%Y-%m-%d %H:%M:%.S'
		HOST=${DEFAULT_HOST}
	fi

	# If HEALTH_CHECK_INTERVAL is zero (not set) default it to DEFAULT_INTERVAL
	if [[ -z "${HEALTH_CHECK_INTERVAL}" ]]; then
		echo "[INFO] HEALTH_CHECK_INTERVAL is not set. For now using default interval of ${DEFAULT_INTERVAL}" | ts '%Y-%m-%d %H:%M:%.S'
		INTERVAL=${DEFAULT_INTERVAL}
	fi
	
	# If HEALTH_CHECK_SILENT is zero (not set) default it to supression
	if [[ -z "${HEALTH_CHECK_SILENT}" ]]; then
		echo "[INFO] HEALTH_CHECK_SILENT is not set. Because this variable is not set, it will be supressed by default" | ts '%Y-%m-%d %H:%M:%.S'
		HEALTH_CHECK_SILENT=1
	fi

	while true; do
		# Ping uses both exit codes 1 and 2. Exit code 2 cannot be used for docker health checks, therefore we use this script to catch error code 2
		ping -c 1 $HOST > /dev/null 2>&1
		STATUS=$?
		if [[ "${STATUS}" -ne 0 ]]; then
			echo "[ERROR] Network is down, exiting this Docker" | ts '%Y-%m-%d %H:%M:%.S'
			exit 1
		fi
		if [ ! "${HEALTH_CHECK_SILENT}" -eq 1 ]; then
			echo "[INFO] Network is up" | ts '%Y-%m-%d %H:%M:%.S'
		fi
		sleep ${INTERVAL}
	done
else
	echo "[ERROR] flaresolverr failed to start!" | ts '%Y-%m-%d %H:%M:%.S'
fi
