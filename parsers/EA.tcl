proc EA {args} {
	if {![string equal [lindex $args 0] [Core::getConfig core serverNumeric]]} { 
		Core::log "core" "notice" "Netburst completed @ [clock format [clock seconds] -format "%T on %D"]"
	}
	exit;
}
