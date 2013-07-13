# A2 B #dev-com 1360425885 +tnCN A2AAD:o
## Channels(lower(name)): <formatted name> <creation time> <modes> <key/0> <limit/-1>
proc B {source token line} { 
	foreach {channel ts} $line { break; }
	set modes ""; set key "0"; set limit -1; set pos 2
	if {[string index [lindex $line 2] 0] == "+"} { 
		# Mode str
		set modes [lindex $line 2]; set pos 3;
		foreach mode [split $modes ""] { 
			if {$mode == "k"} { set key [lindex $line $pos]; incr pos }
			if {$mode == "l"} { set limit [lindex $line $pos]; incr pos }
		}
	}
        if {[string range $modes 0 1] == ":%"} { 
                # the banlist has been continued from the previous burst.
                set banlist [string range [join [lrange [split $data] 4 end]] 2 end];
                foreach ban [split $banlist] { 
                        if {[info exists Data::chanlists([set channel [ircString lower $channel]],b)]} { 
                                lappend Data::chanlists($channel,b) $ban
                        } else { 
                                set Data::channels($channel,b) [list $ban]
                        }
                }
                return
        } 
	set users [lindex $line $pos]; incr pos;
	set banlist [join [lrange $line $pos end]];
	set status "r"; set userlist [list];
	set status_o [list]; set status_v [list]; set status_r [list];
	foreach userToken [split $users ","] { 
		if {[string first ":" $userToken] > -1} { 
			set user [lindex [split $userToken ":"] 0];
			set status [lindex [split $userToken ":"] 1];
		} else { 
			set user $userToken
		}
		if {$status == "ov" || $status == "vo"} { 
			lappend status_o $user;
			lappend status_v $user;
		} else { 
			lappend status_${status} $user;
		}
		lappend userlist $user;
	        if {[lsearch -exact [userChanlist $user] [ircString lower $channel]] == -1} { lappend Data::userchanlists($user) [ircString lower $channel] }
	}
	set Data::channels([ircString lower $channel]) [list $channel $ts $modes $key $limit]
	set Data::chanlists([ircString lower $channel],o) $status_o
	set Data::chanlists([ircString lower $channel],v) $status_v
	set Data::chanlists([ircString lower $channel],r) $status_r
	set Data::chanlists([ircString lower $channel]) $userlist
	#lappend Data::userchanlists($source) [ircString lower $channel]
	if {[debug] == 5} { 
		Connection::sendData "P #dev-com :Channel: $channel - Userlist: $userlist"
	}
	event::trigger "CHANNEL_BURST" $channel
}
