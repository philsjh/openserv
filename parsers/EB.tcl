event::create "SERVICE_READY"

proc EB {source token line} { 
	if {![string equal $source [set Data::Uplink]]} { return; } 
	Connection::sendData "EA";
	event::trigger "SERVICE_READY" [list] 
	Connection::sendData "P #labspace :Bursted in ([expr {([clock clicks]-[set Data::startBurst])/1000.00}] ms.)"
}
