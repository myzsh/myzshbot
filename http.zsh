#!/usr/bin/zsh
set -eu

source json.zsh

zmodload -i zsh/net/tcp
until ztcp -vl 8080; do
	sleep 1
done
listener=$REPLY

source http_router.zsh

http_parser(){
	client=$1
	typeset -A headers
	body=""
	read -r method url http <&$client || ( ztcp -c $client && return )
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
while ztcp -a $listener; do
	http_parser $REPLY
done
