# This is the template for all modules.
namespace eval dummy { 
	variable path "modules/dummy";
	variable spawnOnLoad "[Core::getConfig dummy spawnOnLoad]";
	variable numeric "";
	variable lastUser "";
	variable secureCommands [list]

	# First thing to do is load the commands - this is _BASE_ behaviour.
	namespace eval commands { 

		if {![array exists triggermap]} { array set triggermap [list] }
		if {![array exists registry]} { array set registry [list] }
		proc loadCommands {} { 
			foreach file [glob -nocomplain [set [namespace parent]::path]/commands/*.tcl] { 
				if {[catch {source $file} error]} { 
					Core::log "Dummy" "error" "Could not load command file '[lindex [split [file tail $file] "."] 0]' - error: $error"
				}
			}
		}
		proc reply {message} { 
			::dummy::notice [set ::dummy::lastUser] $message;
		}
		# registercommand <trigger1,trigger2,trigger3/trigger> "description" "syntax" "help string"
		proc registercommand {procedure level triggers description syntax help} { 
			foreach trigger [split $triggers ","] { 
				set trigger [string tolower $trigger];
				if {![info exists [namespace current]::triggermap($trigger)]} {
					set [namespace current]::triggermap($trigger) $procedure
					set [namespace current]::registry($trigger,description) $description
					set [namespace current]::registry($trigger,syntax) $syntax
					set [namespace current]::registry($trigger,help) $help
					set [namespace current]::registry($trigger,level) $level
				}
				# Core::log "dummy" "info" "Command '$trigger' registered to --> $procedure"
			}
		}
	}

	# This is our "constructor" style procedure which does all the loading...
	proc init {} { 
		# Whether we spawn or not, load the commands...
		commands::loadCommands;
		if {[set [namespace current]::spawnOnLoad]} { 
			# Spawn the client here. Method signature: nickname ident hostname modes authname opername fakehost realname
			set [namespace current]::numeric [[namespace current]::buildClientFromConfig];
			Client::joinChannel [set [namespace current]::numeric] "[Core::getConfig core debugChannel]";
			registerEvents;
		} else { 
			# Load everything so we're ready to spawn when LOAD is called.
		}
		return 1;
	}

	proc buildClientFromConfig {} { 
		return "[Client::create [Core::getConfig dummy nickname] [Core::getConfig dummy ident] [Core::getConfig dummy hostname] [Core::getConfig dummy modes] [Core::getConfig dummy authname] [Core::getConfig dummy opername] [Core::getConfig dummy fakehost] [Core::getConfig dummy realname]]"
	}

	# This is our "destructor" style procedure which does all the saving...
	proc destroy {} { 
		# Save any files we need here.
	}

	# This is our "rehasher" style procedure which is a graceful reload.
	proc rehash {} { 
		# Reload commands and refresh any DB access here.
	}

	# Events
	proc registerEvents {} { 
		event::register "USER_PRIVMSG" "chanserv" [namespace current]::onReceivePrivmsg;
	}

	proc userPrivmsg {source target message} { 
		set command [lindex [split $messsage] 0];
		# do whatever we need to with this command now.
	}

	# Useful shortcuts
	proc privmsg {target message} { 
		Client::privmsg [set [namespace current]::numeric] $target $message;
	}

	proc notice {target message} { 
		Client::notice [set [namespace current]::numeric] $target $message;
	}

	proc joinChannel {channel} { 
		Client::joinChannel [set [namespace current]::numeric] $channel;
	}

	proc partChannel {channel {reason ""}} { 
		Client::partChannel [set [namespace current]::numeric] $channel $reason;
	}

	proc servermode {channel mode param} { 
		Connection::sendData "M $channel $mode $param";
	}

	proc mode {channel mode param} { 
		Connection::sendRawData "[set [namespace current]::numeric] M $channel $mode $param";
	}

	proc kick {channel target reason} { 
		Connection::sendRawData "[set [namespace current]::numeric] K $channel $target :${reason}"
	}
}