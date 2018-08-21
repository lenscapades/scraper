#!/usr/bin/perl -w

use lib "$ENV{HOME}/perl5/lib/perl5";
use lib "$ENV{HOME}/scraper/lib";

use strict;
use warnings;

use Data::Dumper;

use Lib::Config;

use Explorer::Parser;

my $config = Lib::Config->new( qw(Explorer) )
	or die "$0 Lib::Config->new() failed";

my $config_parameters = $config->get();

my @Conf = ( {
	target		=> 'bergfuerst',
	type		=> 'explore',
	locale		=> 'de_DE',
	time_zone	=> 'Europe/Berlin',
	file		=> "/bergfuerst.explore.data",
}, {
	target		=> 'companisto', 
	type		=> 'explore', 
	locale		=> 'de_DE',
	time_zone	=> 'Europe/Berlin',
	file		=> "/companisto.explore.data",
}, {
	target		=> 'deutsche-mikroinvest',
	type		=> 'explore',
	locale		=> 'de_DE',
	time_zone	=> 'Europe/Berlin',
	file		=> "/deutsche-mikroinvest.explore.data",
}, {
	target		=> 'exporo',
	type		=> 'explore',
	locale		=> 'de_DE',
	time_zone	=> 'Europe/Berlin',
	file		=> "/exporo.explore.data",
}, {
	target		=> 'indiegogo',
	type		=> 'explore',
	locale		=> 'en_US',
	time_zone	=> 'America/Los_Angeles',
	file		=> "/indiegogo.explore.data",
}, {
	target		=> 'kapilendo',
	type		=> 'explore',
	locale		=> 'de_DE',
	time_zone	=> 'Europe/Berlin',
	file		=> "/kapilendo.explore.data",
}, {
	target		=> 'kickstarter',
	type		=> 'explore',
	locale		=> 'en_US',
	time_zone	=> 'America/New_York',
	file		=> "/kickstarter.explore.data",
}, {
	target		=> 'seedmatch',
	type		=> 'explore',
	locale		=> 'de_DE',
	time_zone	=> 'Europe/Berlin',
	file		=> "/seedmatch.explore.data",
}, {
	target		=> 'startnext',
	type		=> 'explore',
	locale		=> 'de_DE',
	time_zone	=> 'Europe/Berlin',
	file		=> "/startnext.explore.data",
} );

my $choice = undef;

while (1) {

	show_choices();

	$choice = get_choice();

	if ( validate_choice( $choice ) ) {

		do_choice( $choice );

		last unless want_to_continue();
	}
}

sub get_choice {

	my $choice = <>;

	chomp $choice;

	return $choice;
}

sub show_choices {

	system( "clear" );

	print "--------------------------------------------------------------------------\n\n";
	print " Test of Explorer::Parser module\n\n";
	print "--------------------------------------------------------------------------\n\n";

	foreach ( my $i = 0; $i < @Conf; $i++ ) {

		printf( "%2s: %s\n", $i, $Conf[$i]->{target} );
	}

	print "\n";

}

sub validate_choice {

	my $choice = int shift;

	if ( $choice >= 0 && $choice < 9 ) {

		return 1;
	}

	return 0;
}

sub do_choice {

	my $choice = int shift;

	my %params = %{$Conf[$choice]};

	$params{file} = $config_parameters->{test_data} . $params{file};

	my $parser = Explorer::Parser->new( $config_parameters, undef, \%params )
		or die "$0 Explorer::Parser->new() failed";

	my $result = $parser->run();

	if ( $result->is_error ) {

		print $result->message . "\n";
	}
	else {
		if ( my $extra = $result->extra ) {

			print "per page: $extra->{per_page}\n";
		}

		$parser->print( $result->content );
	}	
}

sub want_to_continue {

	print "\nContinue (y/n)?\n";

	my $choice = get_yes_no_choice();

	return ($choice eq "y");
}

sub get_yes_no_choice {

	my $choice;

	while (1) {

		$choice = <>;

		chomp $choice;

		return $1 if ($choice =~ /^(y|n)$/);

		
	}
}
