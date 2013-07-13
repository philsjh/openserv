# Syntax: AB SQ services.playpro.info 1360773312 :Ghost
proc SQ {source token line} { 
	set split [lindex $line 0];
	set numeric [server2num $split];
	set time [lindex $line 1];
	set reason [string range [join [lrange $line 2 end]] 1 end];
	event::trigger "SERVER_QUIT" $source $split $time $reason
	foreach server [array names Data::servers] { 
		if {[string equal -nocase [getServerInfo $server name] $split]} { 
			# Remove this server data.
			unset Data::servers($server);
			break;
		}
	}
	foreach user [serverUserlist $numeric] { 
		::parser::Q $numeric Q "*.net *.split";
	}
}
