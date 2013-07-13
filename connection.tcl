# This file is part of XenosP10

# Connection.tcl
# This establishes the connection to the IRC server and manages the connection
namespace eval Connection { 

	variable socket "";
	variable buffer "";
	variable fileLog [open "log.log" w];

	proc init {} { 
		event::create "DATA_RECEIVE";
		event::create "DATA_SEND";
		if {[set [namespace current]::socket] == ""} { 
			# Socket is empty, lets connect.
			set [namespace current]::socket [socket [Core::getConfig core remoteServerAddress] [Core::getConfig core remoteServerPort]];
			if {[eof [set [namespace current]::socket]]} { 
				# Socket aborted & closed.
				Core::log "Connection" "error" "Could not connect to remote uplink.";
				exit;
			}
			[namespace current]::processLogin;
			fileevent [set [namespace current]::socket] readable [list [namespace current]::handleIncomingData];
			fconfigure [set [namespace current]::socket] -buffering none -blocking 0 -encoding utf-8
			vwait forever;
		}
	}

	proc processLogin {} { 
		sendRawData "PASS :[Core::getConfig core remoteServerPassword]";
		sendRawData "SERVER [Core::getConfig core serverName] 1 [clock seconds] [clock seconds] J10 [Core::getConfig core serverNumeric]\]\]\] [Core::getConfig core serverFlags] :[Core::getConfig core serverDescription]"
		sendData "EB";
		set ::Data::startBurst [clock clicks]
	}

	proc handleIncomingData {} { 
		if {[gets [set [namespace current]::socket] [namespace current]::buffer] < 0 && [eof [set [namespace current]::socket]]} { 
			Core::log "Connection" "error" "Connection closed - no more data to receive.";
			exit;
		} else { 
			# This is where we start to receive the data from the IRC server.
			if {[set [namespace current]::buffer] == "" || [set [namespace current]::buffer] == " "} { return; }
			if {[Core::getConfig core debugLevel] >= 3} { Core::log "Connection" "data" "<- [set [namespace current]::buffer]"; }
			puts [set [namespace current]::fileLog] [set [namespace current]::buffer];
			event::trigger "DATA_RECEIVE" [set [namespace current]::buffer];
		}
	}

	proc sendData {data} { 
		if {![eof [set [namespace current]::socket]]} { 
			sendRawData "[Core::getConfig core serverNumeric] $data";
		} else { 
			Core::log "Connection" "error" "Connection closed - cannot write to socket.";
			exit;
		}
	}

	proc sendRawData {data} { 
		if {![eof [set [namespace current]::socket]]} { 
			puts [set [namespace current]::socket] $data;
			event::trigger "DATA_SEND" $data;
			if {[Core::getConfig core debugLevel] >= 3} { Core::log "Connection" "data" "-> $data" }
		} else { 
			Core::log "Connection" "error" "Connection closed - cannot write to socket.";
			exit;
		}
	}
	init;
}
