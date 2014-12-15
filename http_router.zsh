rpc(){
	ztcp localhost 7000
	# TODO read the banner to make sure we connected ok
	echo "$2" >&$1
	# TODO read a response and print
	ztcp -c $1
}
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

	if [[ "$url" == "/pull" ]]; then
		git pull -f
		source http_router.zsh
		(
			ztcp localhost 7000
			echo "source" >&$REPLY
			ztcp -c $REPLY
		) &
		return
	fi

	if [[ "$url" == "/github" ]]; then
		if [ -z "$body" ]; then
			echo "No body!"
			return
		fi
		if [ -z "${headers[X-GitHub-Event]:-}" ]; then
			echo "No X-GitHub-Event header!"
			return
		fi
		event="${headers[X-GitHub-Event]}"

		echo "parsing body"
		echo "Event type: $event"
		JSON.load "$body" jason
		mkdir hooks 2>/dev/null || true
		echo "$body" > hooks/${headers[X-GitHub-Delivery]}.json

		if [[ "$event" == "push" ]]; then
			whom="$(JSON.get -s /pusher/name jason)"
			commits="commit"
			number=$(echo "$jason" | grep -cE "^/commits/[0-9]*/id")
			[[ "$number" -gt 1 ]] && commits="commits"
			branch="$(basename "$(JSON.get -s /ref jason)")"
			repo="$(JSON.get -s /repository/name jason)"
			force="$(JSON.get /forced jason)"
			[[ "$force" == "false" ]] && force="" || force="forced "
			rpc $client "msg #myzsh $whom ${force}pushed $number $commits to $repo @$branch"
		else
			rpc $client "msg #myzsh Event of type $event: ${headers[X-GitHub-Delivery]}"
		fi

	fi

	echo "HTTP/1.1 200 OK" >&$client
	echo "Content-type: text/plain" >&$client
	echo "Content-Length: 0" >&$client
	echo "Connection: close" >&$client
}

