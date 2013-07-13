# Register our events here.
event::create "USER_SETFAKEHOST"
event::create "USER_OPER"
event::create "USER_DELFAKEHOST"
event::create "USER_DEOPER"
event::create "USER_MODE"

proc M {source token line} { 
	set target [ircString lower [lindex $line 0]];
	if {[string index $target 0] == "#"} { 
		parseChannelModeChange $source $token $line;
	} else { 
		parseUserModeChange $source $token $line;
	}
}

proc isChanUserMode {mode} { 
	if {$mode == "v" || $mode == "b" || $mode == "o"} { 
		return 1;
	} 
	return 0;
}
## Users(numeric): <nickname> <server> <hops> <connectTime> <ident> <hostname> <modes/0> <authname/0> <opername/0> <fakehost/0> baseip <realname>
proc parseUserModeChange {source token line} { 
	set target [lindex $line 0];
	if {[string equal -nocase $target [getUserInfo $source nickname]]} { 
		set modestr [lindex $line 1];
		set pos 2; set type "+";
		set opername ""; set fakehost "";
		set current [getUserInfo $source modes];
		foreach mode [split $modestr ""] { 
			if {$mode == "+" || $mode == "-"} { 
				set type $mode;
			} else {
				if {$mode == "h"} { 
					if {$type == "+"} { set fakehost [lindex $line $pos]; event::trigger "USER_SETFAKEHOST" $source $fakehost }
					if {$type == "-"} { event::trigger "USER_DELFAKEHOST" [list $source]; }
					incr pos
				} elseif {$mode == "o" || $mode == "O"} { 
					if {$type == "+"} { set opername [lindex $line $pos]; event::trigger "USER_OPER" $source $opername }
					if {$type == "-"} { event::trigger "USER_DEOPER" [list $source] }
					incr pos
				} 
				if {$type == "+" && [string first $mode $current] == -1} { append current $mode; event::trigger "USER_MODE" $source ${type}${mode} }
				if {$type == "-" && [string first $mode $current] != -1} { 
					set current [string map [list $mode ""] $current]
					event::trigger "USER_MODE" $source ${type}${mode}
				}
			}
		}
		if {$opername != ""} { set Data::users($source) [lreplace [set Data::users($source)] 8 8 $opername] }
		if {$fakehost != ""} { set Data::users($source) [lreplace [set Data::users($source)] 9 9 $fakehost] }
		set Data::users($source) [lreplace [set Data::users($source)] 6 6 $current] 
		if {[debug] == 5} { 
			Connection::sendData "P #dev-com :User: $target - Modes: [join [lrange [set Data::users($source)] 5 8]]"
		}
	}
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
				if {$change == "k"} { set var "key"; event::trigger "CHANNEL_MODE" $source $channel ${action}${change} [lindex $line $parameter]; }
				if {$change == "l"} { set var "limit"; event::trigger "CHANNEL_MODE" $source $channel ${action}${change} [lindex $line $parameter]; }
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
	## Channels(lower(name)): <formatted name> <creation time> <modes> <key/0> <limit/-1> <topic_setby> <topic_setTS> <topic>
	set Data::channels($channel) [lreplace [set Data::channels($channel)] 2 2 $currentModes];
	set Data::channels($channel) [lreplace [set Data::channels($channel)] 3 3 $key];
	set Data::channels($channel) [lreplace [set Data::channels($channel)] 4 4 $limit];
	if {[debug] == 5} { 
		Connection::sendData "P #dev-com :${source} set mode $line on $channel.";
		Connection::sendData "P #dev-com :Channel Status Now:";
		Connection::sendData "P #dev-com :Operators: [set Data::chanlists($channel,o)]"
		Connection::sendData "P #dev-com :Voice: [set Data::chanlists($channel,v)]"
		Connection::sendData "P #dev-com :Regular: [set Data::chanlists($channel,r)]";
		Connection::sendData "P #dev-com :Modes: $currentModes"
	}
}
