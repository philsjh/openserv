proc G {source token line} { 
	set ts [string range [lindex $line 0] 1 end];
	set target [lindex $line 1];
	Connection::sendData "Z [Core::getConfig core serverNumeric] $source $ts [expr {([clock seconds]-$ts)*1000}] [clock seconds].[expr {[clock milliseconds]-([clock seconds]*1000)}]"
}
