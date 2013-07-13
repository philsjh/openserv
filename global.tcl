# Data arrangement:
## Servers(numeric): <server_name> <parent> <hops> <boottime> <linktime> <flags> <description>
## Users(numeric): <nickname> <server> <hops> <connectTime> <ident> <hostname> <modes/0> <authname/0> <opername/0> <fakehost/0> baseip <realname>
## Channels(lower(name)): <formatted name> <creation time> <modes> <key/0> <limit/-1> 
## Chanlists(lower(name),<status>): <list of users>
## ChanTopic(lower(name)) "<set by (nickname!user@host)> <set time> <topic string>"
## -- where <status> can be: o, v, r or null

namespace eval Data { 
	variable Uplink "";

	variable startBurst 0;
	variable endBurst 0;
	set array_list [list "servers" "users" "channels" "chanlists" "userchanlists" "authnames" "chanserv_channels" "chanserv_chanlevs" "nick2num" "pushmode" "chanserv_bans" "chanserv_log" "help_triggers" "help_friends" "away" "server2num" "staff_fakehosts"]
	foreach array $array_list { 
		if {![array exists $array]} { 
			array set $array [list]
		}
	}
}

# Trap signals
trap sigintHandler SIGINT;

proc sigintHandler {} { 
	event::trigger SIGINT
	after 1000 [list Connection::sendData "SQ [Core::getConfig core serverName] :Service shutting down"];
	after 1200 [list exit];
}

proc rand {min max} {
         return [expr {int(rand()*($max-$min+1)+$min)}]
}

# Gets the debug level.
proc debug {} { 
	if {[Core::getConfig core debugLevel] != ""} { 
		return [Core::getConfig core debugLevel];
	} else { 
		return 5
	}
}

proc getChildServers {numeric} { 
	set list [list];
	foreach server [array names Data::servers] { 
		if {[getServerInfo $server parent] == $numeric} { 
			lappend list $server;
		}
	}
}

proc serverUserlist {numeric} { 
	set list [list];
	foreach user [array names Data::users] { 
		if {[getUserInfo $user server] == $numeric} { 
			lappend list $user;
		}
	}
	return $list;
}

proc userChanlist {numeric} { 
	if {[info exists Data::userchanlists($numeric)]} { 
		return [set Data::userchanlists($numeric)];
	}
	return "";
}

proc nick2num {nickname} { 
	set nickname [ircString lower $nickname];
	if {[info exists Data::nick2num($nickname)]} { return [set Data::nick2num($nickname)] }
	return "0";
}

proc server2num {server} { 
	set server [string tolower $server];
	if {[info exists Data::server2num($server)]} { return [set Data::server2num($server)] }
	return 0;
}

proc chanlist {channel} { 
	set channel [ircString lower $channel];
	if {[info exists Data::chanlists($channel)]} { 
		return [set Data::chanlists($channel)];
	} 
	return "";
}

proc strToSeconds {str} { foreach match [regexp -all -inline {[0-9]+[A-Za-z]+} $str] { regexp -all {([^a-zA-Z]+?)} $match -> number; regexp -all {([^0-9]+?)} $match -> letter; if {$letter == "w"} { incr time [expr {604800*$number}] } elseif {$letter == "d"} { incr time [expr {$number * 86400}] } elseif {$letter == "h"} { incr time [expr {$number*3600}] } elseif {$letter == "m"} { incr time [expr {$number*60}] } elseif {$time == "s"} { incr time $number }  }; return $time; }
# Gets the clones of an IP.
proc getClones {source {return "0"}} { 
	set count "0"; set resultList [list];
	foreach user [array names Data::users] { 
		if {[getUserInfo $user baseip] == [getUserInfo $source baseip] && ![string equal $user $source]} { 
			incr count;
			if {$return == 1} { lappend resultList $user }
			if {$return == 2} { lappend resultList [getUserInfo $user nickname] }
		}
	}
	if {$return > 0} { return $resultList; }
	return $count;
}
proc isAway {numeric} { 
	return [info exists Data::away($numeric)]
}
proc isop {numeric channel} { 
	set channel [ircString lower $channel];
	if {[info exists Data::chanlists($channel,o)] && [lsearch -exact [set Data::chanlists($channel,o)] $numeric] > -1} { 
		return 1;
	}
	return 0;
}

proc isvoice {numeric channel} {
        set channel [ircString lower $channel];
        if {[info exists Data::chanlists($channel,v)] && [lsearch -exact [set Data::chanlists($channel,v)] $numeric] > -1} {
                return 1;
        }
        return 0;
}

proc ison {numeric channel} { 
	set channel [ircString lower $channel];
	if {[lsearch -exact [chanlist $channel] $numeric] > -1} { 
		return 1;
	} 
	return 0;
}

proc isService {numeric} { 
	if {[string equal [string range $numeric 0 1] [Core::getConfig server serverNumeric]]} { return 1; }
	if {[string first "s" [getServerInfo [getUserInfo $numeric server] flags]] > -1} { return 1; }
	if {[string length [getUserInfo $numeric nickname]] == -1} { return 1; }
	return 0;
}

proc isOper {numeric} { 
	if {[string first "o" [getUserInfo $numeric modes]] > -1} { return 1; } 
	return 0;
}

proc userHasServiceFlag {numeric} { 
	if {[string first "k" [getUserInfo $numeric modes]] > -1} { return 1; }
	return 0;
}

proc userHasXtraOper {numeric} { 
	if {[string first "X" [getUserInfo $numeric modes]] > -1} { return 1; }
	return 0;
}

proc getbanmask {numeric} { 
	if {[string first "h" [getUserInfo $numeric modes]] > -1 && [getUserInfo $numeric fakehost] != "0"} { 
		set banmask "*![string map [list "~" "*"] [getUserInfo $numeric fakehost]]";
	} elseif {[set authname [getUserInfo $numeric authname]] != "0"} { 
		set banmask "*!*@${authname}.[Core::getConfig network hiddenhost]";
	} else {
		set banmask "*![string map [list "~" "*"] [getUserInfo $numeric ident]]@[getUserInfo $numeric hostname]";
	}
	return $banmask;
}

proc matchban {mask user} { 
	set hosts [list];
	if {[getUserInfo $user fakehost] != "0"} { lappend hosts "[getUserInfo $user nickname]![getUserInfo $user fakehost]"; }
	lappend hosts "[getUserInfo $user nickname]![getUserInfo $user ident]@[getUserInfo $user hostname]";
	if {[getUserInfo $user authname] != "0"} { lappend hosts "[getUserInfo $user nickname]![getUserInfo $user ident]@[getUserInfo $user authname].[Core::getConfig network hiddenhost]" }
	foreach host $hosts { 
		if {[string match -nocase $mask $host]} { 
			return 1;
		}
	}
	return 0;
}

## Channels(lower(name)): <formatted name> <creation time> <modes> <key/0> <limit/-1>
proc getChanInfo {name returnValue} {
	set name [ircString lower $name];
        if {![info exists Data::channels($name)]} {
                return "0"
        }
        set arrangement [list name creation modes key limit];
        set returnValue [string tolower $returnValue];
        if {[set loc [lsearch -exact $arrangement $returnValue]] > -1} {
                return [lindex [set Data::channels($name)] $loc];
        } else {
                return "0";
        }
}

proc getServerInfo {numeric returnValue} {
        if {![info exists Data::servers($numeric)]} {
                return "0"
        }
        set arrangement [list name parent hops boottime linktime flags description];
        set returnValue [string tolower $returnValue];
        if {[set loc [lsearch -exact $arrangement $returnValue]] > -1} {
                if {$returnValue == "description"} {
                        return [join [lrange [set Data::servers($numeric)] $loc end]];
                } else {
                        return [lindex [set Data::servers($numeric)] $loc];
                }
        } else {
                return "0";
        }
}

proc getUserInfo {numeric returnValue} { 
	if {![info exists Data::users($numeric)]} { 
		return "0"
	} 
	set arrangement [list nickname server hops connecttime ident hostname modes authname opername fakehost baseip realname];
	set returnValue [string tolower $returnValue];
	if {[set loc [lsearch -exact $arrangement $returnValue]] > -1} { 
		if {$returnValue == "realname"} { 
			return [join [lrange [set Data::users($numeric)] $loc end]];
		} else { 
			return [lindex [set Data::users($numeric)] $loc];
		}
	} else { 
		return "0";
	}
}
proc getServerUsers {server} { 
	set returnlist [list];
	foreach user [array names Data::users] { 
		if {[getUserInfo $user server] == $server} { 
			lappend returnlist $user;
		}
	}
	return $returnlist;
}

# Because of IRC's scandanavian origin, the characters {}| are considered to be the lower case equivalents of the characters []\, respectively. 
# This is a critical issue when determining the equivalence of two nicknames.
proc getFlagChanges {original flags} { 
	set type "+";
	foreach flag [split $flags ""] { 
		if {$flag == "+" || $flag == "-"} { set type $flag; }
		if {$type == "-" && [string first $flag $original] > -1} { set original [string map [list $flag ""] $original]; }
		if {$type == "+" && [string first $flag $original] == -1} { append original $flag; }
	}
	return $original;
}
proc randString {{length "8"}} { 
	set characters "_+-ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!"
        set password ""
        for {set x "0"} {$x <= $length} {incr x} { 
        	append password "[lindex [split $characters ""] [rand 0 [llength [split $characters ""]]]]"
        }
        return $password
}
proc ircString {type str {compare ""}} { 
	if {$type == "lower"} { 
		set str [string map {"\[" "\{" "\]" "\}" "|" "\\"} $str];
		return [string tolower $str];
	} elseif {$type == "upper"} { 
		set str [string map {"\{" "\[" "\}" "\]" "\\" "|"} $str];
		return [string toupper $str];
	} elseif {$type === "equal"} { 
		return [string equal [ircString lower $str] [ircString lower $compare]]
	}
}


# IP Stuff

# Converts a B64 IP to a long
proc b64dc {b64} {
        # Base64 Converting stuff
        set b64charset [split {ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789[]} ""]
        # b64 to int
        set num 0; set i [string length $b64]; incr i -1
        foreach char [split $b64 ""] {
                set num [expr {$num + (wide(1)<<(6*$i)) * [lsearch -exact $b64charset $char]}]
                incr i -1
        }
        return $num
        }
# Converts a long int to a B64 IP
proc b64ec {int {fill 0}} {
        # Base64 Converting stuff
        set b64charset [split {ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789[]} ""]
        set result ""
        while {$int > 0} {
                set result [lindex $b64charset [expr {wide($int) & 0x3F}]]$result
                set int [expr {wide($int) >> 6}]
        }
        while {[string length $result] < $fill} {
                set result A$result
        }
        return $result
}
# Converts a long int to an IPv4 address
proc int2ip {num} {
        binary scan [binary format I $num] cccc a b c d
        set ip [format %d.%d.%d.%d [expr $a&255] [expr $b&255] [expr $c&255] [expr $d&255]]
}
# Converts an IPv4 IP address to a long
proc ip2int {ip} {
        foreach {a b c d} [split $ip .] { break }
        set num [expr {(((((wide($a)<<8)+$b)<<8)+$c)<<8)+$d}]
        return $num
}

proc getIP {baseip} { 
	return [int2ip [b64dc $baseip]];
}

##########################
# Pushmode
##########################

proc pushmode {numeric channel mode {param ""} {queuespeed "medium"}} { 
	set channel [ircString lower $channel];
	if {$queuespeed == "slow"} { set speed "400"; 
	} elseif {$queuespeed == "medium"} { set speed "200"; 
	} elseif {$queuespeed == "fast"} { set speed "75"; 
	} elseif {$queuespeed == "instant"} { set speed "1"; }
	if {![string equal -nocase $mode "--flush"]} { 
		if {[info exists Data::pushmode($numeric,$channel)]} { 
			set queue [set Data::pushmode($numeric,$channel)]
			set modeCurrent [lindex [split $queue] 0];
			set userCurrent [lrange [split $queue] 1 end];
			append modeCurrent $mode;
			if {$param != ""} { lappend userCurrent $param; }
			set Data::pushmode($numeric,$channel) "$modeCurrent [join $userCurrent]";
			puts "Queue now: $modeCurrent [join $userCurrent]";
		} else { 
			if {$param != ""} { 
				set Data::pushmode($numeric,$channel) "$mode $param" 
			} else { 
				set Data::pushmode($numeric,$channel) $mode 
			}
		}
		if {[llength [lrange [split [set Data::pushmode($numeric,$channel)]] 1 end]] == 6} { pushmode $numeric $channel --flush }
		after $speed [list pushmode $numeric $channel --flush]
	} else { 
		if {[info exists Data::pushmode($numeric,$channel)]} { 
			set modes [lindex [split [set Data::pushmode($numeric,$channel)]] 0];
			set params [join [lrange [split [set Data::pushmode($numeric,$channel)]] 1 end]];
			puts "Executing Queue --> $modes $params";
			Connection::sendRawData "$numeric M $channel $modes $params";
			unset Data::pushmode($numeric,$channel);
		}
	}
}
