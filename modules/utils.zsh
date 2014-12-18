msg(){
	local target="$1"
	local msg="$2"

	msg="${msg//{white\}/\x030}"
	msg="${msg//{black\}/\x031}"
	msg="${msg//{blue\}/\x032}"
	msg="${msg//{green\}/\x033}"
	msg="${msg//{red\}/\x034}"
	msg="${msg//{brown\}/\x035}"
	msg="${msg//{purple\}/\x036}"
	msg="${msg//{orange\}/\x037}"
	msg="${msg//{yellow\}/\x038}"
	msg="${msg//{lgreen\}/\x039}"
	msg="${msg//{lcyan\}/\x0310}"
	msg="${msg//{lblue\}/\x0311}"
	msg="${msg//{lpurple\}/\x0312}"
	msg="${msg//{grey\}/\x0313}"
	msg="${msg//{lgrey\}/\x0314}"
	msg="${msg//{reset\}/\x03}"
	
	echo "Sending '$msg' to $target"
	print "PRIVMSG $target :$msg" >&$ircfd
}
