namespace eval Module { 

	proc load {module} { 
		if {[file exists modules/$module/${module}.tcl]} { 
			if {[catch {uplevel #0 source modules/$module/${module}.tcl} error]} { 
				Core::log "Module" "error" "Unable to load module '$module' - error: $error";
				return $error;
			}
			if {[catch {::${module}::init} error]} { 
				Core::log "Module" "error" "Unable to initialize module '$module' - error: $error";
				Core::log "Module" "error" $::errorInfo
				if {[namespace exists ::${module}]} { 
					namespace delete ::${module}
				}
				return $error;
			} else { 
				return 1;
			}
		} else { 
			Core::log "Module" "error" "Unable to load module '$module' - error: no such file or directory."
			return "no such file or directory";
		}
	}

	proc unload {module} { 
		if {![namespace exists ::${module}]} { 
			return 0;
		}
		if {[catch {::${module}::destroy} error]} { 
			Core::log "Module" "error" "Unable to unload module '$module' - error: $error"
			Core::log "Module" "info" "Cleaning up after failed unload attempt...";
		}
		namespace delete ::${module};
		return 1;
	}

	proc loaded {module} { 
		return [namespace exists ::${module}];
	}

	proc automatedLoad {args} { 
		set modlist [list];
		foreach item [array names Core::configuration] { 
			foreach {mod setting} [split $item ","] { break; }
			if {[lsearch -exact $modlist $mod] == -1} { 
				if {[Core::getConfig $mod spawnOnLoad]} { 
					[namespace current]::load $mod;
				}
				lappend modlist $mod 
			}
		}
	}

	event::register "SERVICE_READY" Module [namespace current]::automatedLoad;
}
