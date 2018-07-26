#!/bin/bash
# bash web crawler
# $ bash crawl.sh http://example.com

# from here
# https://gist.github.com/antoineMoPa/ada42dcfc96197e38dc8c4df363aed72

WORK_DIR="work"

rm -fr "$WORK_DIR"

mkdir -p "$WORK_DIR"

URL_TEXT="${WORK_DIR}/urls.txt"
SUB_URLS_TXT="${WORK_DIR}/sub-urls.txt"
SUB_2_URLS_TXT="${WORK_DIR}/sub-2-urls.txt"

# create new empty files
touch $URL_TEXT
touch $SUB_URLS_TXT
touch $SUB_2_URLS_TXT

site=$1
proxy_ip=$2
proxy_port=$3

function visit() {
	echo visiting "$1"

	# get URLs
	curl -x "$3:$4" -silent "$1" | grep href=\" | grep "http://" | grep -o "http:\\/\\/[^\"]*" | sed 's/<.*//' >>"$2"
}

visit "$site" "$URL_TEXT" "$proxy_ip" "$proxy_port"

while
	read -r line
do
	(echo "$line" | grep 'zip') && continue
	(echo "$line" | grep 'pdf') && continue
	visit "$line" "$SUB_URLS_TXT" "$proxy_ip" "$proxy_port"
done <"$URL_TEXT"

while
	read -r line
do
	(echo "$line" | grep 'zip') && continue
	(echo "$line" | grep 'pdf') && continue
	visit "$line" "$SUB_2_URLS_TXT" "$proxy_ip" "$proxy_port"
done <$SUB_URLS_TXT
