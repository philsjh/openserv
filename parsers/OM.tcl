proc OM {source token line} { 
	set target [ircString lower [lindex $line 0]];
	if {[string index $target 0] == "#"} { 
		parseChannelModeChange $source $token $line;
	} 
}

proc isChanUserMode {mode} { 
	if {$mode == "v" || $mode == "b" || $mode == "o"} { 
		return 1;
	} 
	return 0;
}

proc parseChannelModeChange {source token line} { 
	set channel [ircString lower [lindex $line 0]];
	set changes [lindex $line 1];
	set action "+"; set parameter 2;
	set key "0"; set limit -1;
	set currentModes [getChanInfo $channel modes];
	foreach change [split $changes ""] { 
		if {$change == "+" || $change == "-"} { 
			set action $change;
		} else { 
			if {$action == "+"} { 
				set var "";
				if {![isChanUserMode $change]} { 
					append currentModes $change;
					if {$change != "k" && $change != "l"} { 
						event::trigger "CHANNEL_MODE" $source $channel ${action}${change}
					}
				}
				if {$change == "k"} { set var "key"; event::trigger "CHANNEL_MODE" $source $channel ${action}${change} [lindex $line $parameter] }
				if {$change == "l"} { set var "limit"; event::trigger "CHANNEL_MODE" $source $channel ${action}${change} [lindex $line $parameter] }
				if {$change == "o" || $change == "v" || $change == "b"} { 
					lappend Data::chanlists($channel,$change) [lindex $line $parameter];
					if {[isop [lindex $line $parameter] $channel] || [isvoice [lindex $line $parameter] $channel]} { 
						set Data::chanlists($channel,r) [lreplace [set Data::chanlists($channel,r)] [set location [lsearch -exact [set Data::chanlists($channel,r)] [lindex $line $parameter]]] $location]
					}
					event::trigger "CHANNEL_MODE" $source $channel ${action}${change} [lindex $line $parameter]
					incr parameter;
				}
				if {$var != ""} { 
					set $var [lindex $line $parameter];
					incr parameter;
				}
			} else { 
				if {![isChanUserMode $change] && [string first $change $currentModes] > -1} { 
					set currentModes [string map {"$change" ""} $currentModes];
					if {$change != "k" && $change != "l"} { 
						event::trigger "CHANNEL_MODE" $source $channel ${action}${change}
					}
				}
				if {$change == "k"} { set key "0"; event::trigger "CHANNEL_MODE" $source $channel ${action}${change} }
				if {$change == "l"} { set limit -1; event::trigger "CHANNEL_MODE" $source $channel ${action}${change} }
				if {$change == "o" || $change == "v" || $change == "b"} { 
					set Data::chanlists($channel,$change) [lreplace [set Data::chanlists($channel,$change)] [set position [lsearch -exact [set Data::chanlists($channel,$change)] [lindex $line $parameter]]] $position]
					if {![isop [lindex $line $parameter] $channel] && ![isvoice [lindex $line $parameter] $channel]} { 
						lappend Data::chanlists($channel,r) [lindex $line $parameter];
					}
					event::trigger "CHANNEL_MODE" $source $channel ${action}${change} [lindex $line $parameter]
					incr parameter;
				}
			}
		}
	}
	if {[debug] == 5} { 
		Connection::sendData "P #dev-com :${source} set mode $line on $channel.";
		Connection::sendData "P #dev-com :Channel Status Now:";
		Connection::sendData "P #dev-com :Operators: [set Data::chanlists($channel,o)]"
		Connection::sendData "P #dev-com :Voice: [set Data::chanlists($channel,v)]"
		Connection::sendData "P #dev-com :Regular: [set Data::chanlists($channel,r)]";
		Connection::sendData "P #dev-com :Modes: $currentModes"
	}
}
