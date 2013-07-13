# This file is part of XenosP10

# Parser.tcl
# This gets the data from the IRC server and parses it into seperate parser files.
namespace eval Parser { 
	variable activeParsers [list];

	event::register "DATA_RECEIVE" Parser [namespace current]::handleData;
	event::register "DATA_SEND" Parser [namespace current]::handleData;
	proc handleData {buffer} { 
		# Time to decide what token type this is.
		set splitBuffer [split $buffer];
		if {[tokenHasSrc [lindex $splitBuffer 0]]} { 
			# Token has a source.
			set source [lindex $splitBuffer 0];
			set token [lindex $splitBuffer 1];
			set arg [lrange $splitBuffer 2 end];
		} else { 
			set source "";
			set token [lindex $splitBuffer 0];
			set arg [lrange $splitBuffer 1 end];
		}
		[namespace current]::parseToken $source $token $arg
	}

	proc parseToken {source token arg} { 
		# Pass the token and the data to our parser.
		if {[lsearch -exact [set [namespace current]::activeParsers] $token] == -1} { return; }
		if {[catch {[namespace current]::${token} $source $token $arg} error]} { 
			##Core::log "Parser" "error" "Unable to parse token '$token' - error: $error";
			if {![string match "*invalid command name*" $error]} { 
				Core::log "Parser" "error" "Unable to parse token '$token' - error: $error";
			}
		}
	}

	proc init {} { 
		set parser_fail [list]
		set [namespace current]::activeParsers [list];
		foreach file [glob -nocomplain parsers/*.tcl] { 
			if {[catch {source $file} error]} { 
				if {[Core::getConfig core debugLevel] >= 1} { Core::log "Parser" "error" "Skipping parser '[lindex [split [file tail $file] "."] 0]' - error: $error" }
				lappend parser_fail [list [lindex [split [file tail $file] "."] 0] [list $error]];
			} else { 
				if {[Core::getConfig core debugLevel] >= 4} { Core::log "Parser" "debug" "Loaded parser file '[lindex [split [file tail $file] "."] 0]'." }
				lappend [namespace current]::activeParsers [lindex [split [file tail $file] "."] 0];
			}
		}
		if {[llength $parser_fail] == 0} { 
			return 1;
		} else { 
			return $parser_fail;
		}
	}

	proc tokenHasSrc {token} { 
		set tokenNoSrc [list "PASS" "ERROR" "SERVER"];
		if {[lsearch -exact $tokenNoSrc $token] >= 0} { 
			return 0;
		} else { 
			return 1;
		}
	}
	init;
}
