# Syntax: <source> AC <numeric> <authname>
proc AC {source token line} { 
	set numeric [lindex $line 0];
	set authname [lindex $line 1];
	set modes [getUserInfo $numeric modes];
	if {[string first "r" $modes] == -1} { 
		append modes "r";
	}
	set Data::users($numeric) [lreplace [set Data::users($numeric)] 6 6 $modes];
	set Data::users($numeric) [lreplace [set Data::users($numeric)] 7 7 $authname];
	event::trigger "USER_AUTHED" $numeric $authname
}
