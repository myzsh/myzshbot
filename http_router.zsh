rpc(){
	ztcp localhost 7000
	# TODO read the banner to make sure we connected ok
	echo "$1" >&$REPLY
	# TODO read a response and print
	ztcp -c $REPLY
}

http_reload(){
	until git pull -f; do
		sleep 1
	done
	source http_router.zsh
	rpc "source"
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
		http_reload
	elif [[ "$url" == "/github" ]]; then
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
			branch="$(basename "$(JSON.get -s /ref jason)")"
			repo="$(JSON.get -s /repository/name jason)"
			force="$(JSON.get /forced jason)"
			[[ "$force" == "false" ]] && force="" || force="forced "
			url="$(JSON.get -s /compare jason)"
			msg=""
			if [[ "$number" -gt 1 ]]; then
				commits="commits"
			else
				msg="\"$(JSON.get -s /commits/0/message jason)\" "
			fi
			rpc "msg #myzsh $whom ${force}pushed $number $commits to $repo @$branch ${msg}$url"
			if [[ "$repo" == "myzshbot" ]] && [[ "$branch" == "master" ]]; then
				rpc "msg #myzsh reloading modules"
				http_reload
			fi
		else
			rpc "msg #myzsh Event of type $event: ${headers[X-GitHub-Delivery]}"
		fi

	fi

	echo "HTTP/1.1 200 OK" >&$client
	echo "Content-type: text/plain" >&$client
	echo "Content-Length: 0" >&$client
	echo "Connection: close" >&$client
}

