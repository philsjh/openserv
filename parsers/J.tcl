# <client> J <channel>
proc J {source token line} { 
	set channel [ircString lower [lindex $line 0]];
	if {$channel == "0"} { 
		foreach channel [userChanlist $source] { 
			[namespace current]::L $source "L" [list $channel "Left all channels"]
		}
		return;
	}
	if {[lsearch -exact [chanlist $channel] $source] == -1} { lappend Data::chanlists($channel) $source; }
	if {[lsearch -exact [userChanlist $source] $channel] == -1} { lappend Data::userchanlists($source) $channel; }
	if {[lsearch -exact [set Data::chanlists($channel,r)] $source] == -1} { lappend Data::chanlists($channel,r) $source; }
	if {[debug] == 5} { 
		Connection::sendData "P #dev-com :[getUserInfo $source nickname] joined $channel.";
	}
	event::trigger "USER_JOIN" $source $channel
}
