msg(){
	echo "Sending '$2' to $1"
	print "PRIVMSG $1 :$2" >&$ircfd
}
