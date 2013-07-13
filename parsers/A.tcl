proc A {source token line} { 
	set awaymsg [string range [join [lrange $line 1 end]] 1 end];
	if {[string length $awaymsg] > 0} { 
		set Data::away($source) [list [clock seconds] [list $awaymsg]]
	} else { 
		if {[info exists Data::away($source)]} { unset Data::away($source); }
	}
	event::trigger "USER_AWAY" $source $awaymsg;
}
