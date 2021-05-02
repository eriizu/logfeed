#!/bin/sh

set -e

if [ ! -z $1 ]; then
	echo " -> info: using first parameter as file to watch and pseudo-rotate $1"
	FILE_WATCHED=$1
fi

FILE_WATCHED="${FILE_WATCHED:-"/var/log/access.log"}"
# Container to kill can remain blank if you are not using it.
#
# CONTAINER_TO_KILL="${CONTAINER_TO_KILL:-traefik}"

# Storage directory for goaccess' cache.
DATA_DIR="${DATA_DIR:-"/data"}"

# File that goaccess will produce; can be of any type it supports.
OUTPUTFILE="${OUTPUTFILE:-"/output/blog.html"}"

# Filters to use with grep when ingesting logs, use line breaks in between each entry.
MATCH=$(echo -e "ghost")
INVTERTED_MATCH=$(echo -e "/ghost/\n/api/\nHEAD\n/assets/")

echo " -> info: watching $1"

# This file name is used to store the logs when processing them with goaccess.
# mktemp suffixes are commented out, because not all implemntations support them.
#
# TMP_FILE=$(mktemp --suffix=.log)
TMP_FILE=$(mktemp)

# This file-flag is used to check if the script needs to continue or not.
# It is deleted when gracefully stopping--for instance.
#
# RUN_FLAG=$(mktemp --suffix=.flag)
RUN_FLAG=$(mktemp)

function gracefull_stop() {
	echo ":: Gracefully stopping..."
	rm $RUN_FLAG
}

trap gracefull_stop INT TERM

# needs
#     volumes:
#      - /var/run/docker.sock:/var/run/docker.sock
# ref https://stackoverflow.com/questions/30775628/docker-how-to-send-a-signal-from-one-running-container-to-another-one#30781156
function kill_usr_container() {
	docker kill --signal USR1 $1

	# Original line of code, meant to write directly on socket, but few nc implementation actually support -U
	# it became easier to use an image that includes docker-cli.
	#
	# echo -e "POST /containers/$1/kill?signal=SIGUSR1 HTTP/1.0\r\n" | nc -U /var/run/docker.sock
}

while [ -f $RUN_FLAG ]; do
	if [ -f $FILE_WATCHED ]; then
		mv $FILE_WATCHED $TMP_FILE
		touch $FILE_WATCHED
		if [ ! -z $CONTAINER_TO_KILL ]; then
			kill_usr_container $CONTAINER_TO_KILL
		fi
		cat $TMP_FILE | grep "$MATCH" | grep -h -v "$INVTERTED_MATCH" | goaccess - -o $OUTPUTFILE --log-format COMBINED --persist --restore --db-path=$DATA_DIR --anonymize-ip --double-decode --ignore-crawlers --real-os --no-global-config --ignore-status=404 --ignore-panel=NOT_FOUND --ignore-panel=REFERRING_SITES --ignore-panel=REFERRERS --ignore-panel=KEYPHRASES --ignore-panel=GEO_LOCATION --no-query-string
		# goaccess $TMP_FILE -o blog.html --log-format COMBINED --persist --restore --anonymize-ip --double-decode --ignore-crawlers --real-os
		rm $TMP_FILE
	else
		echo " -> the file to watch doesn't exist, yet?"
	fi
	echo ":: Waiting 1 minute..."
	sleep 1m
	# sleep 5m
done
