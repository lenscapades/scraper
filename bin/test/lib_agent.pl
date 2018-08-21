#!/usr/bin/perl -w

use lib "$ENV{HOME}/perl5/lib/perl5";
use lib "$ENV{HOME}/scraper/lib";

use strict;
use warnings;

use Data::Dumper;

use Lib::Config;

my $config = Lib::Config->new(qw(Scraper));

my $config_parameters = $config->get();

use Lib::Agent;

my $agent = Lib::Agent->new( $config_parameters );

my $this_agent = $agent->get( 111, { locale => 'de_DE' } );

print Dumper( $this_agent->agent ) . "\n";
print Dumper( $this_agent->headers ) . "\n";
print Dumper( $this_agent->cookie_jar ) . "\n";

$this_agent->clear_cookie_jar();
