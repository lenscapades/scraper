#!/usr/bin/perl -w

use lib "$ENV{HOME}/perl5/lib/perl5";
use lib "$ENV{HOME}/scraper/lib";

use strict;
use warnings;

my $config = {

	log_file => "$ENV{HOME}/scraper/var/tmp/test.log",

	log_level => 3,

	time_zone => {

		local => "Europe/Berlin",

		standard => "Europe/Berlin",
	}
};

use Lib::Logging;

my $logging = new Lib::Logging( $config )
	or die "$0 Lib::Logging->new() failed";

$logging->caller( "Test" );

$logging->entry( 1, "Test entry" );

$logging->entry( 2, "Another test entry ..." );
