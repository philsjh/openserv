proc GL {source token line} { 
	# <numeric> GL <target> <!/+/-><mask> <expiration> <lastmod> <lifetime> :<reason>
	set server [lindex [split $line] 0];
	if {[string equal $server [Core::getConfig core serverNumeric]]} {
		# our server numeric..
		# but we are a services server, we don't handle client connections
		# send an error back to the sender
		Conn
		return;
	}
	if {$server != "*"} {
		# propogated local gline, not for us
		# ignore it
		return;
	}
}
