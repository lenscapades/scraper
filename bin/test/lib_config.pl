#!/usr/bin/perl -w

use lib "$ENV{HOME}/perl5/lib/perl5";
use lib "$ENV{HOME}/scraper/lib";

use strict;
use warnings;

use Data::Dumper;

use Lib::Config;

my $config = new Lib::Config( qw(Json_Api) )
	or die "$0 Lib::Config->new() failed";

print "--------------------------------------------------------------------------\n\n";
print " Test for Lib::Config module\n\n";
print "--------------------------------------------------------------------------\n\n";

my $config_data = $config->get();

print Dumper( $config_data );
