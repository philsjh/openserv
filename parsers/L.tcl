proc L {source token line} {
        set channel [ircString lower [lindex $line 0]];
	if {[llength [chanlist $channel]] == 0} { 
		# Destroy the channel
		event::trigger "CHANNEL_DESTROY" $channel;
		unset Data::chanlists($channel);
		foreach user [array names Data::users] { 
			if {[set s [lsearch -exact [userChanlist $user] $channel]]] > -1} { 
				set Data::userchanlists($source) [lreplace [userChanlist $user] $s $s];
			}
		}
		unset Data::chanlists($channel,o);
		unset Data::chanlists($channel,v);
		unset Data::chanlists($channel,r);
		return;
	}
	set message [string range [join [lrange $line 1 end]] 1 end];
        if {[set loc [lsearch -exact [chanlist $channel] $source]] > -1} {
                set Data::chanlists($channel) [lreplace [set Data::chanlists($channel)] $loc $loc];
        }
	if {[set loc [lsearch -exact [userChanlist $source] $channel]] > -1} { 
		set Data::userchanlists($source) [lreplace [set Data::userchanlists($source)] $loc $loc];
	}
	set checklist "[list $channel,o $channel,v $channel,r]";
	foreach array $checklist { 
		if {[set loc [lsearch -exact [set Data::chanlists($array)] $source]] > -1} {
			set Data::chanlists($array) [lreplace [set Data::chanlists($array)] $loc $loc];
		}
	}
        if {[debug] == 5} {
                Connection::sendData "P #dev-com :[getUserInfo $source nickname] left $channel ([expr {$message == "" ? "No message." : $message}]).";
        }
        event::trigger "USER_PART" $source $channel
}
