proc W {source token line} { 
	foreach {server nickname} $line { break; }
	if {![string equal $server [Core::getConfig core serverNumeric]]} { return; }
	set nickname [string range $nickname 1 end];
	set numeric [nick2num $nickname]
	if {$numeric == "0"} { return; }
	Connection::sendData "311 $source $nickname [getUserInfo $numeric ident] [getUserInfo $numeric hostname] * :[getUserInfo $numeric realname]";
	Connection::sendData "312 $source $nickname [Core::getConfig network HISName] :[Core::getConfig core serverDescription]";
	if {[string first "o" [getUserInfo $numeric modes]] > -1} { 
		Connection::sendData "313 $source $nickname :is an IRC Operator";
		if {[string first "n" [Core::getConfig core serverFlags]] > -1} { Connection::sendData "343 $source $nickname [getUserInfo $numeric opername] :is opered as"; }
	}
	if {[getUserInfo $numeric authname] != "0"} { Connection::sendData "330 $source $nickname [getUserInfo $numeric authname] :is authed as"; }
	Connection::sendData "318 $source $nickname :End of /WHOIS list.";
}
