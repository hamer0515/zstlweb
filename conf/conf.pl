#!/usr/bin/perl

{

	# db information
	dsn    => "dbi:DB2:$ENV{DB_NAME}",
	user   => $ENV{DB_USER},
	pass   => $ENV{DB_PASS},
	schema => $ENV{DB_SCHEMA},

	port => $ENV{LISTEN_PORT},

	#server
	svc_url => $ENV{SVC_URL},

	#mgr
	mgr_url => $ENV{MGR_URL},

	#memcached server
	mem_server => [ $ENV{MEM_SERVER} ],

	#expire
	expire => 14400,

	di => [ a .. z, A .. Z, 0 .. 9 ],

};

