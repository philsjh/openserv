# <source> K <channel> <numeric> :<reason>
proc K {source token line} { 
	set channel [ircString lower [lindex $line 0]]; set victim [lindex $line 1];
	set reason [string range [join [lrange $line 2 end]] 1 end];
	event::trigger "USER_KICK" $source $channel $victim $reason
	set chanlist_list [list $channel $channel,o $channel,v $channel,r]
	foreach chanlist $chanlist_list { 
		if {[set p [lsearch -exact [set Data::chanlists($chanlist)] $victim]]} { set Data::chanlists($chanlist) [lreplace [set Data::chanlists($chanlist)] $p $p] }
	}
}
