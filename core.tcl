#!/etc/bin/tclsh

namespace eval Core {

    if {[info patchlevel] < 8.5} {
            puts "This service requires a TCL version of at least 8.5";
            exit;
    }

    if {[catch {package require Expect} error]} { 
	    puts "Expect not found - signals will not work.";
    }

    foreach file [glob -nocomplain libs/*.tcl] { 
	if {[catch {uplevel #0 source $file} error]} { 
		puts "Could not load library file '[file tail $file]' - error: $error";
	}
    }

    # Our main logging function - everything gets passed to here.
    proc log {zone level str} {
        puts "\[[clock format [clock seconds] -format "%T"]\] (${zone})${level}: $str";
    }

    proc version {} { 
	return "0.92-DEV";
    }

    proc getConfig {module item} { 
        if {[info exists [namespace current]::configuration($module,$item)]} { 
            return [set [namespace current]::configuration($module,$item)];
        }
        return "0";
    }
    proc init {} {
        # Create our arrays.
        set arrays "[list configuration]"
        foreach array $arrays { 
            if {![array exists $array]} { 
                array set $array [list];
            }
        }
        # Parse a configuration file.
        # Firstly check if the configuration file exists - if not, exit.
        if {![file exists service.conf]} { 
            log "core" "error" "Could not find a configuration file.";
            exit;
        } else { 
            set f [open service.conf r];
            set fdata [read -nonewline $f];
            set section "";
            foreach line [split $fdata "\n"] { 
                if {$line == "" || $line == " "} {
                    continue;
                } else { 
                    if {[string range $line 0 1] == "//"} { continue; }
                    if {[string index $line 0] == "\[" && [string index $line end] == "\]"} { 
                        set section [string range $line 1 end-1]; 
                        continue;
                    }
                    foreach {option value} [split $line "="] { break; }
                    set [namespace current]::configuration($section,[string trim $option]) [string trim $value];
                }
            }
        }
        # Load the rest of the service here - always load event first.
        set files [list "event.tcl" "global.tcl" "parser.tcl" "module.tcl" "database.tcl" "client.tcl" "connection.tcl"];
        foreach file $files {
            if {[file exists $file]} {
                if {![catch {uplevel #0 source $file} error]} { continue; }
                log "core" "error" "Could not load file '$file' - error: $error"
		puts $::errorInfo;
		exit;
            } else {
                log "core" "error" "Could not load file '$file' - error: file not found."
            }
        }
    }

    proc reloadConfig {} {
        if {![file exists service.conf]} {
            log "core" "error" "Could not find a configuration file.";
	    return "Could not find a configuration file named 'service.conf'";
        } else {
            set f [open service.conf r];
            set fdata [read -nonewline $f];
            set section "";
            foreach line [split $fdata "\n"] {
                if {$line == "" || $line == " "} {
                    continue;
                } else {
                    if {[string range $line 0 1] == "//"} { continue; }
                    if {[string index $line 0] == "\[" && [string index $line end] == "\]"} {
                        set section [string range $line 1 end-1];
                        continue;
                    }
                    foreach {option value} [split $line "="] { break; }
                    set [namespace current]::configuration($section,[string trim $option]) [string trim $value];
                }
            }
        }
	if {[catch {uplevel #0 source global.tcl} error]} { return $error; }
	return 1;
    }
    init;
}
