# This namespace enables us to create users on our server. (for modules and such)
namespace eval Client { 

	proc create {nickname ident hostname modes authname opername fakehost realname} { 
		set modes [string map [list "h" "" "o" "" "r" ""] $modes];
		if {[string first "r" $modes]} { 
			append modes "r"
			if {$authname == "0"} { set authname $nickname; }
		} 
		if {[string first "o" $modes]} { 
			append modes "o"
			if {$opername == "0"} { set opername $nickname; }
		}
		if {[string first "h" $modes]} { 
			if {$fakehost != "0"} { 
				append modes "h"
			} else { 
				set modes [string map [list "h" ""] $modes];
			}
		}
		set numeric [[namespace current]::findFreeClientNumeric];
		set time [clock seconds]
		Connection::sendData [join "N $nickname 1 $time $ident $hostname $modes [expr {$authname == "0" ? "" : $authname}] [expr {$opername == "0" ? "" : $opername}] B]AAAB $numeric :${realname}"]
		return $numeric;
	}

	proc destroy {numeric {reason ""}} { 
		if {$reason == ""} { set reason "Quit: Signed off"; }
		Connection::sendRawData "$numeric Q :${reason}";
	}

        proc findFreeClientNumeric {} { 
                set charlist "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890[]";
                set numeric "[Core::getConfig core serverNumeric]";
                for {set i 2} {[string length $numeric] != 5} {incr i} { 
                        append numeric [lindex [split $charlist ""] [expr {int(rand()*([llength [split $charlist ""]]+1))}]]
                }
                if {[info exists Data::users($numeric)]} { [namespace current]::findFreeClientNumeric }
                return $numeric;
        }

	proc joinChannel {numeric channel {opmode "1"}} { 
		if {![info exists Data::channels([ircString lower $channel])]} { 
			Connection::sendRawData "$numeric C $channel [clock seconds]";
		} else { 
			Connection::sendRawData "$numeric J $channel [getChanInfo $channel creation]"
			if {$opmode} { Connection::sendData "M $channel +o $numeric" }
		}
	}

	proc partChannel {numeric channel {reason ""}} { 
		Connection::sendRawData "$numeric L $channel :${reason}"
	}

	proc privmsg {numeric target message} { 
		Connection::sendRawData "$numeric P $target :${message}"
	}

	proc notice {numeric target message} { 
		Connection::sendRawData "$numeric O $target :${message}"
	}

	proc hop {numeric channel} { 
		[namespace current]::partChannel $channel;
		[namespace current]::joinChannel $channel;
	}
}
