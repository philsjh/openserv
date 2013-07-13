# Syntax: <numeric> Q :<reason>
event::create "USER_QUIT"
proc Q {source token line} { 
	set reason [string range [join $line] 1 end];
	event::trigger "USER_QUIT" $source $reason
	foreach channel [userChanlist $source] { 
		foreach channel_list [list "$channel" "$channel,o" "$channel,v" "$channel,r"] { 
			if {[info exists Data::chanlists($channel_list)] && [set l [lsearch -exact [set Data::chanlists($channel_list)] $source]] > -1} { 
				set Data::chanlists($channel_list) [lreplace [set Data::chanlists($channel_list)] $l $l];
			}
		}
	}
	if {[info exists Data::userchanlists($source)]} { unset Data::userchanlists($source) }
	if {[info exists Data::nick2num([ircString lower [getUserInfo $source nickname]])]} { unset Data::nick2num([ircString lower [getUserInfo $source nickname]]) }
	if {[info exists Data::users($source)]} { unset Data::users($source) }
}
