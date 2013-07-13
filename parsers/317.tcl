#AC 317 CSRdP r0t3n 41 1362160886 :seconds idle, signon time

proc 317 {source token line} { 
	foreach {target nickname idletime signon} $line { break; }
	puts "Target: $target - Nickname: $nickname - Idletime: $idletime - Signon: $signon"
	if {![string equal [Core::getConfig core serverNumeric] [string range $target 0 1]]} {  return; }
	puts "Trigging USER_IDLETIME"
	event::trigger "USER_IDLETIME" $target $nickname $idletime $signon
}
