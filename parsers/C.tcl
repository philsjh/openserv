## Channels(lower(name)): <formatted name> <creation time> <modes> <key/0> <limit/-1>
## Chanlists(lower(name),<status>): <list of users>
## ChanTopic(lower(name)) "<set by (nickname!user@host)> <set time> <topic string>"
proc C {source token line} {
	foreach {fchannel timestamp} $line { break; }
	set channel [ircString lower $fchannel];
	set Data::channels($channel) "[list $fchannel $timestamp 0 0 -1]";
	set Data::chanlists($channel) [list $source];
	set Data::chanlists($channel,o) [list $source];
	set Data::chanlists($channel,v) [list];
	set Data::chanlists($channel,r) [list];
	if {[debug] == 5} { 
		Connection::sendData "P #dev-com :[getUserInfo $source nickname] created '$fchannel'";
	}
	event::trigger "CHANNEL_CREATED" [list $channel $source $timestamp];
}
