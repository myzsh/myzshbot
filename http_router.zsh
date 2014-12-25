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

# [{purple}myzsh-docker{reset}] dan9186 created {purple}change-dev-mapped-dir{reset} (+1 new commit): {blue}https://github.com/myzsh/myzsh-docker/commit/b0614575bde3
# {purple}myzsh-docker{reset}/{purple}change-dev-mapped-dir{reset} b061457 Daniel Hess: changing to /docker per issue #4
# [{purple}myzsh-docker{reset}] dan9186 opened pull request #9: changing to /docker per issue #4 ({purple}master{reset}...{purple}change-dev-mapped-dir{reset}) {blue}https://github.com/myzsh/myzsh-docker/pull/9

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
			rpc "msg #myzsh [{purple}$repo{reset}/{purple}$branch{reset}] $whom ${force}pushed $number $commits ${msg}{blue}$url"
			if [[ "$repo" == "myzshbot" ]] && [[ "$branch" == "master" ]]; then
				rpc "msg #myzsh reloading modules"
				echo "HTTP/1.1 200 OK" >&$client
				echo "Content-type: text/plain" >&$client
				echo "Connection: close" >&$client
				echo "" >&$client
				echo "Reloading modules" >&$client
				ztcp -c $client
				http_reload
				return
			fi
		elif [[ "$event" == "pull_request" ]]; then
			who="$(JSON.get -s /pull_request/user/login jason)"
			title="$(JSON.get /pull_request/title jason)"
			url="$(JSON.get -s /pull_request/html_url jason)"
			if [[ "$(JSON.get -s /action)" == "opened" ]]; then
				rpc "msg #myzsh [{purple}$repo{reset}] $who opened pull request $title {blue}$url"
			elif [[ "$(JSON.get -s /action)" == "labeled" ]]; then
				label="$(JSON.get /label/name jason)"
				rpc "msg #myzsh [{purple}$repo{reset}] $who labeled pull request $title as $label {blue}$url"
			fi
		elif [[ "$event" == "issue_comment" ]]; then
			who="$(JSON.get -s /issue/user/login jason)"
			title="$(JSON.get /issue/title jason)"
			url="$(JSON.get -s /issue/html_url jason)"
			rpc "msg #myzsh [{purple}$repo{reset}] $who commented on issue $title {blue}$url"
		elif [[ "$event" == "pull_request_review_comment" ]]; then
			who="$(JSON.get -s /comment/user/login jason)"
			title="$(JSON.get /pull_request/title jason)"
			url="$(JSON.get -s /comment/url jason)"
			rpc "msg #myzsh [{purple}$repo{reset}] $who commented on pull request $title {blue}$url"
		elif [[ "$event" == "page_build" ]]; then
			repo="$(JSON.get -s /repository/name jason)"
			who="$(JSON.get -s /comment/user/login jason)"
			status="$(JSON.get -s /build/status jason)"
			url="http://$(JSON.get -s /repository/name jason)"
			if [[ "$status" == "built" ]]; then
				rpc "msg #myzsh [{purple}$repo{reset}] {blue}$url{reset} rebuilt successfully."
			else
				rpc "msg #myzsh [{purple}$repo{reset}] {blue}$url{reset} page_build status $status."
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

