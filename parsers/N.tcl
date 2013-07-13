# Src: A2 - Token: N - Arg: Modul8 1 1360420433 ~modul8 host-92-17-250-191.as13285.net +oiwkgxXnIhP Modul8 modul8@localhost BcEfq\] A2AAB :Modul8
## Users(numeric): <nickname> <hops> <connecttime> <ident> <hostname> <modes/0> <authname/0> <opername/0> <fakehost/0> baseip <realname>
event::create "USER_CONNECTED"
event::create "USER_NICKCHANGE"

proc N {source token line} { 
	foreach {nickname hops timestamp ident hostname} $line { break; }
	if {[llength $line] <= 4} { 
		# Nick change here.
		set new_nick [lindex $line 0];
		set old_nick [getUserInfo $source nickname];
		set Data::users($source) [lreplace [set Data::users($source)] 0 0 $new_nick];
		set Data::nick2num([ircString lower $new_nick]) $source;
		unset Data::nick2num([ircString lower $old_nick]);
		event::trigger "USER_NICKCHANGE" $source $old_nick $new_nick
		return;
	}
	if {[string index [lindex $line 5] 0] == "+"} { 
		# We have modes;
		set modes [lindex $line 5]; set pos 6;
		set fakehost "0"; set opername "0"; set authname "0";
		set authdetails "0";
		foreach mode [split $modes ""] { 
			if {$mode == "h"} { set fakehost [lindex $line $pos]; incr pos; }
			if {$mode == "r"} { set authdetails [lindex [split [lindex $line $pos] ":"] 0]; incr pos; }
			if {$mode == "o"} { set opername [lindex $line $pos]; incr pos; }
		}
	} else { 
		set modes ""; set pos 5;
	}
	set baseip [lindex $line $pos]; incr pos;
	set numeric [lindex $line $pos]; incr pos;
	set description [string range [join [lrange $line $pos end]] 1 end];
	if {[debug] == 5} { 
		Connection::sendData "P #dev-com :Found a user ($nickname/$numeric) ($ident@$hostname) - Modes: $modes - BaseIP: $baseip"
	}
	set Data::users($numeric) [list $nickname $source $hops $timestamp $ident $hostname $modes $authdetails $opername $fakehost $baseip $description]
	set Data::nick2num([ircString lower $nickname]) $numeric;
	set Data::userchanlists($numeric) [list]
	event::trigger "USER_CONNECTED" $numeric;
	if {[string first $modes "r"] > -1} { event::trigger "USER_AUTHED" $numeric $authdetails }
	if {[string first $modes "h"] > -1} { event::trigger "USER_FAKEHOST" $numeric $fakehost }
	if {[string first $modes "o"] > -1} { event::trigger "USER_OPER" $numeric $opername; }
}
