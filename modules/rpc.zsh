do_rpc() {
	client=$1
	rpc=$2
	if [[ "$clientin" =~ "^msg ([^ ]+) (.*)" ]]; then
		msg "${match[1]}" "${match[2]}"
	elif [[ "$clientin" =~ "^ztcp" ]]; then
		ztcp -L >&$client
	elif [[ "$clientin" =~ "^source" ]]; then
		module_reload
	fi
}
