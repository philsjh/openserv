# This file is part of XenosP10.

# Our main event namespace.
namespace eval event {
    # Variables
    variable eventList  [list];
    # Arrays
    if {![array exists registry]} { array set registry [list]; }

    # Creates an event.
    proc create {name} {
        if {[lsearch -exact [set [namespace current]::eventList] [string tolower $name]] >= 0} {
            return 0;
        } else {
            lappend [namespace current]::eventList $name;
            return 1;
        }
    }

    # Removes an event.
    proc delete {name} {
        if {[set location [lsearch -exact [set [namespace current]::eventList] [string tolower $name]]] == -1} {
            return 0;
        } else {
            lreplace [namespace current]::eventList $location $location;
            return 1;
        }
    }

    # Registers for an event.
    proc register {name module procedure} {
	set name [string tolower $name];
        if {[info exists [namespace current]::registry($name,$module)]} {
            return 0;
        } else {
            set [namespace current]::registry($name,$module) $procedure
            if {[Core::getConfig core debugLevel] >= 4} { Core::log "events" "info" "$module has registered for event '$name'" }
            return 1;
        }
    }
    # Unregisters for an event.
    proc unregister {name module} {
	set name [string tolower $name];
        if {![info exists [namespace current]::registry($name,$module)]} {
            return 0;
        } else {
            unset [namespace current]::registry($name,$module)
            return 1;
        }
    }

    # Triggers an event
    proc trigger {event args} {
        set event [string tolower $event];
        foreach eventStack [array names [namespace current]::registry "$event,*"] {
	    set eventProc $event::registry($eventStack);
            if {[catch {uplevel #0 ${eventProc} $args} error]} { 
                if {[Core::getConfig core debugLevel] >= 2} { Core::log "events" "error" "Error executing event for $eventProc - error: $error"; }
            }
        }
    }
}
