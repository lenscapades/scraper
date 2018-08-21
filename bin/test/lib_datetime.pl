#!/usr/bin/perl -w

use lib "$ENV{HOME}/perl5/lib/perl5";
use lib "$ENV{HOME}/scraper/lib";

use strict;
use warnings;

my $config = {

	time_zone => {

		local => "Europe/Berlin",

		standard => "Europe/Berlin",
	}
};

use Lib::Datetime;

my $datetime = new Lib::Datetime( $config );

#my $ts_now = time();

#my $dt_now = $datetime->long( $ts_now );

#$print "$ts_now\n";

my $dt_now = '2017-04-19 23:22:39';

print "$dt_now\n";

my $epoch = $datetime->epoch( $dt_now );

print "$epoch\n";

my $ts_local =  $datetime->epoch_local( $dt_now );

print "$ts_local\n";

print $datetime->long( $ts_local ) . "\n";

print $datetime->offset( $dt_now, -6 * 60 * 60 ) . "\n";

print $datetime->offset( $dt_now, -24 * 60 * 60 ) . "\n";
