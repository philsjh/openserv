# Syntax: <numeric> CM <channel> <modes>
        ## Channels(lower(name)): <formatted name> <creation time> <modes> <key/0> <limit/-1> <topic_setby> <topic_setTS> <topic>
#        set Data::channels($channel) [lreplace [set Data::channels($channel)] 2 2 $currentModes];
#        set Data::channels($channel) [lreplace [set Data::channels($channel)] 3 3 $key];
#        set Data::channels($channel) [lreplace [set Data::channels($channel)] 4 4 $limit];
proc CM {source token line} { 
	foreach {channel modes} $line { break; }
	set channel [ircString lower $channel];
	set chanmodes [getChanInfo $channel modes];
	foreach mode [split $modes ""] { 
		if {$mode == "o" || $mode == "v" || $mode == "b"} { set Data::channels($channel,$mode) [list] }
		if {$mode == "k"} { set Data::channels($channel) [lreplace [set Data::channels($channel) 3 3] }
		if {$mode == "l"} { set Data::channels($channel) [lreplace [set Data::channels($channel) 4 4] }
		if {[string first $mode $chanmodes] > -1} { set chanmodes [string map [list $mode ""] $chanmodes]; }
		event::trigger "CHANNEL_CLEARMODE" $source $channel $mode;
	}
	set Data::channels($channel) [lreplace [set Data::channels($channel)] 2 2 $chanmodes];
}
