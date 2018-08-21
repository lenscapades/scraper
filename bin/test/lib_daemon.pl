#!/usr/bin/perl -w

use lib "$ENV{HOME}/perl5/lib/perl5";
use lib "$ENV{HOME}/scraper/lib";

use strict;
use warnings;

use Data::Dumper;

my $config = {

	log_file => "$ENV{HOME}/scraper/var/tmp/daemon.log",

	log_level => 3,

	db_file => "$ENV{HOME}/scraper/var/tmp/daemon.db",

	time_zone => {

		local => "Europe/Berlin",

		standard => "Europe/Berlin",
	}
};

use Lib::Logging;

my $logging = new Lib::Logging( $config )
	or die "$0 Lib::Logging->new() failed";

$logging->caller( "Daemon" );

use Lib::Info;

my $info = new Lib::Info( $config )
	or die "$0 Lib::Info->new() failed";

use Lib::Daemon;

my $test_daemon = new TestDaemon( $logging, $info );

$test_daemon->daemonize();

package TestDaemon;

sub new {

	my $class = shift;

	my $self = {};

	bless( $self, $class );

	$self->{logging} = shift;

	$self->{info} = shift;

	return $self;
}

sub daemonize {

	my $self = shift;

	my $pid = $self->{info}->get_pid();

	if ( defined($pid) && $pid ne "" && kill(0, $pid) ) {

		print( "Another TestDaemon is running (pid $pid).\nQuitting ...\n" );
		exit(1);
	}

	$self->{daemon} = new Lib::Daemon( "TestDaemon" )
		or die __PACKAGE__ . "->daemonize() Lib::Daemon->new() failed";

	$self->{daemon}->run( \$self );
}

sub verbose {

	my $self = shift;

	return 1;
}

sub run {

	my $self = shift;

	print "Daemon running ... \n";

	## perform some time consuming task here ##
	sleep(5);
}

1;
