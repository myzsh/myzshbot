server_msg() {
	num="$1"
	msg="$2"
	if [[ $num = "001" ]]; then
		print "Got a connect message."
		print "JOIN #myzsh" >&$ircfd
	else
		print "server_msg: Can't parse $num $msg"
	fi
}
