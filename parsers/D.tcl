# Syntax: <source> D <numeric>
event::create "USER_KILLED";

proc D {source token line} { 
	set victim [lindex $line 0];
        set reason [string range [join [lrange $line 2 end]] 1 end-1];
	if {[string first "!" $reason] > -1} { 
		foreach {path reason} [split $reason "!"] { break; }
	}
        event::trigger "USER_KILLED" $source $victim $reason
        foreach channel [userChanlist $victim] {
                foreach channel_list [list "$channel" "$channel,o" "$channel,v" "$channel,r"] {
                        if {[info exists Data::chanlists($channel_list)] && [set l [lsearch -exact [set Data::chanlists($channel_list)] $victim]] > -1} {
                                set Data::chanlists($channel_list) [lreplace [set Data::chanlists($channel_list)] $l $l];
                        }
                }
        }
        if {[info exists Data::userchanlists($victim)]} { unset Data::userchanlists($victim) }
        if {[info exists Data::users($victim)]} { unset Data::users($victim); }
}
