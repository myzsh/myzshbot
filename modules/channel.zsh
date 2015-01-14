channel_msg() {
	who="$1"
	channel="$2"
	msg="$3"
	if [[ $msg = "%ping" ]]; then
		print "Got a pong msg."
		msg "#$channel" "pong"
	elif [[ $msg = "%reload" ]]; then
		module_reload
		msg "#$channel" "Module reload successful"
	elif [[ $msg = "%dantime" ]]; then
		dantime="$(TZ=PST8PDT date)"
		msg "#$channel" "Dan time is currently $dantime"
	else
		print "channel_msg: Can't parse $who $channel $msg"
	fi
}
