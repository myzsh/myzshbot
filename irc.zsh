#!/usr/bin/zsh
set -euo pipefail

module_reload(){
	for m in modules/*.zsh; do
		source "$m"
	done
}

module_reload

zmodload -i zsh/net/tcp
zmodload -i zsh/stat

ztcp chat.freenode.net 6667
ircfd=$REPLY


print 'NICK myzshbot' >&$ircfd
print 'USER myzshbot "" "" :myzshbot' >&$ircfd

ztcp -vl 7000
listener=$REPLY

trap "{ztcp -c}" EXIT
clients=()

input="xxx"
while [ -n "$input" ]; do
	if read -rt 0.1 input <&$ircfd; then
		input=${input[0,$[ ${#input} - 1 ]]}
		if [[ "$input" =~ ":([^ ]+) ([0-9]+) ([^ ]+) :(.*)" ]]; then
			server_msg ${match[2]} "${match[4]}"
		elif [[ "$input" =~ ":([^ ]+) PRIVMSG #([^ ]+) :(.*)" ]]; then
			channel_msg ${match[1]} ${match[2]} ${match[3]}
		elif [[ "$input" =~ "PING :(.*)" ]]; then
			print "PONG :${match[1]}" >&$ircfd
		else
			print "No idea how to parse $input."
		fi
	elif ztcp -vta $listener; then
		client=$REPLY
		print "Got an rpc connection"
		print "RPC Welcome" >&$client
		clients+=($client)
	fi
	for ((i=${#clients};i>0;i--)); do
		start=${(%):-%D\{%s\}}
		if read -rt 2 clientin <&${clients[$i]}; then
			do_rpc ${clients[$i]} $clientin
		else
			end=${(%):-%D\{%s\}}
			if [[ $end = $start ]]; then
				echo "Closing client socket"
				ztcp -c ${clients[$i]} || true
				clients[$i]=()
			fi
		fi
	done
done

