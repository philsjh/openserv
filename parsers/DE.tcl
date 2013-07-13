proc DE {source line} { 
	set channel [ircString lower [lindex $line 0]];
	if {[info exists Data::channels($channel)]} { unset Data::channels($channel) }
	foreach user [chanlist $channel] { 
		if {[set l [lsearch -exact [userChanlist $user] $channel]] > -1} { 
			set Data::userchanlists($user) [lreplace [userChanlist $user] $l $l];
		}
	}
	if {[info exists Data::chanlists($channel)]} { unset Data::chanlists($channel) }
	event::trigger "CHANNEL_DESTRUCT" $channel [clock seconds];
}
