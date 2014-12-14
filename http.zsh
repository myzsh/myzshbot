#!/usr/bin/zsh
set -euo pipefail

source json.zsh

zmodload -i zsh/net/tcp
until ztcp -vl 8080; do
	sleep 1
done
listener=$REPLY

http_router(){
	client=$1
	url=$2
	body=$3
	shift 3
	local -A headers
	set -A headers "$@"
	echo "Got a route request for $url"
	for h in "${(k)headers[@]}"; do
		echo "$h: ${headers[$h]}"
	done
	[[ "$url" == "/quit" ]] && ztcp -c && exit 2

	if [[ "$url" == "/github" ]]; then
		if [ -z "$body" ]; then
			echo "No body!"
			return
		fi
		if [ -z "${headers[X-GitHub-Event]:-}" ]; then
			echo "No X-GitHub-Event header!"
			return
		fi

		echo "parsing body"
		echo "Event type: ${headers[X-GitHub-Event]}"
		JSON.load "$body" jason
		mkdir hooks 2>/dev/null || true
		echo "$body" > hooks/${headers[X-GitHub-Delivery]}.json

		ztcp localhost 7000
		echo "msg #myzsh Event of type ${headers[X-GitHub-Event]}: ${headers[X-GitHub-Delivery]}" >&$REPLY
		ztcp -c $REPLY
	fi

	echo "HTTP/1.1 200 OK" >&$client
	echo "Content-type: text/plain" >&$client
	echo "Content-Length: 0" >&$client
	echo "Connection: close" >&$client
}

http_parser(){
	client=$1
	typeset -A headers
	body=""
	read -r method url http <&$client
	headers[METHOD]=method
	headers[HTTP]=http
	url="${url//\/\///}"
	while read -r input <&$client; do
		input="${input//$'\r'/}"
		if [[ ${#input} == 0 ]]; then
			# if there's a content-length
			# read exactly that much into body
			if [[ "$method" == "POST" ]]; then
				if [[ -n "${headers[Content-Length]}" ]]; then
					read -rk "${headers[Content-Length]}" -u $client -t 2 body
					if [[ ${#body} != ${headers[Content-Length]} ]]; then
						echo "Tried to read in ${headers[Content-Length]} bytes but only read ${#body} bytes"
					fi
				fi
			fi
			http_router "$client" "$url" "$body" ${${(@qkv)headers}[*]}
			break
		fi
		headers[${input%: *}]="${input#*: }"
	done
	ztcp -c $client
}

trap "{ztcp -c}" EXIT
while ztcp -va $listener; do
	http_parser $REPLY
done
