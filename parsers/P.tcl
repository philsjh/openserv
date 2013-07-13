proc P {source token line} { 
	set target [lindex $line 0];
	set message [string range [join [lrange $line 1 end]] 1 end];
	if {![string equal [string range $target 0 1] [Core::getConfig core serverNumeric]] && ![string equal -nocase [lindex [split $target "@"] end] [Core::getConfig core serverName]] && [string index $target 0] != "#"} { 
		return;
	}
	event::trigger "USER_PRIVMSG" $source $target $message
}
