# AB S cust.fr.playpro.info 2 0 1360326981 P10 ACAP] +h6n :PlayPro Irc server, France
## Servers(numeric): <server_name> <parent> <hops> <boottime> <linktime> <flags> <description>
proc S {source token line} { 
	foreach {name hops boot link protocol numeric flags} $line { break; }
	set description [string range [join [lrange $line 7 end]] 1 end];
	set shortNumeric "[string range $numeric 0 1]";
	if {[debug] == 5} { 
		Connection::sendData "P #dev-com :Found new server - name: $name - Protocol: $protocol - Description: $description";
	}
	set Data::servers($shortNumeric) [list $name $source $hops $boot $link $flags $description]
	set Data::server2num([string tolower $name]) $shortNumeric;
	event::trigger "SERVER_CONNECTED" $numeric;
}
