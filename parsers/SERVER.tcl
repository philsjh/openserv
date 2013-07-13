# SERVER cust.se.playpro.info 1 1360111404 1360338980 J10 ABAP] +h6n :PlayPro Irc server, Sweden
## Servers(numeric): <server_name> <parent> <hops> <boottime> <linktime> <flags> <description>
proc SERVER {source token line} { 
	foreach {server hops boot link protocol numeric serverflags} $line { break; }
	set description [string range [join [lrange $line 7 end]] 1 end];
	set shortnumeric [string range $numeric 0 1];
	if {![string equal $shortnumeric [Core::getConfig core serverNumeric]]} { set Data::Uplink $shortnumeric; }
	if {[debug] == 5} { 
		Connection::sendData "P #dev-com :We are connected to $server - running protocol '$protocol' - it has been connected since [clock format $link -format "%D %T"]";
	}
	set Data::servers($shortnumeric) [list $server 0 $hops $boot $link $serverflags $description]
	set Data::servers([string tolower $server]) $shortnumeric
	event::trigger "SERVER_CONNECTED" $numeric;
}
