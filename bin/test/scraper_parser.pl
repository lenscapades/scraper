#!/usr/bin/perl -w

use lib "$ENV{HOME}/perl5/lib/perl5";
use lib "$ENV{HOME}/scraper/lib";

use strict;
use warnings;

use Data::Dumper;

use Lib::Config;

use Scraper::Parser;

my $config = Lib::Config->new( qw(Scraper) )
	or die "$0 Lib::Config->new() failed";

my $config_parameters = $config->get();

my @Conf = ( {
	target		=> 'bergfuerst',
	type		=> 'scrape',
	locale		=> 'de_DE',
	time_zone	=> 'Europe/Berlin',
	file		=> "/bergfuerst.scrape.data",
}, {
	target		=> 'bergfuerst',
	type		=> 'scrape',
	locale		=> 'de_DE',
	time_zone	=> 'Europe/Berlin',
	file		=> '/gera.terminated.data',
}, {
	target		=> 'bergfuerst',
	type		=> 'scrape',
	locale		=> 'de_DE',
	time_zone	=> 'Europe/Berlin',
	file		=> '/leipzig.terminated.data',
}, {
	target		=> 'companisto', 
	type		=> 'scrape', 
	locale		=> 'de_DE',
	time_zone	=> 'Europe/Berlin',
	file		=> "/ase.data",
}, {
	target		=> 'companisto', 
	type		=> 'scrape', 
	locale		=> 'de_DE',
	time_zone	=> 'Europe/Berlin',
	file		=> "/golf4you.hours2.data",
}, {
	target		=> 'deutsche-mikroinvest',
	type		=> 'scrape',
	locale		=> 'de_DE',
	time_zone	=> 'Europe/Berlin',
	file		=> "/deutsche-mikroinvest.scrape.data",
}, {
	target		=> 'exporo',
	type		=> 'scrape',
	locale		=> 'de_DE',
	time_zone	=> 'Europe/Berlin',
	file		=> "/exporo.scrape.data",
}, {
	target		=> 'indiegogo',
	type		=> 'scrape',
	locale		=> 'en_US',
	time_zone	=> 'America/Los_Angeles',
	file		=> "/indiegogo.everything.data",
}, {
	target		=> 'indiegogo',
	type		=> 'scrape',
	locale		=> 'en_US',
	time_zone	=> 'America/Los_Angeles',
	file		=> "/indiegogo.scrape1.data",
}, {
	target		=> 'indiegogo',
	type		=> 'scrape',
	locale		=> 'en_US',
	time_zone	=> 'America/Los_Angeles',
	file		=> "/indiegogo.fundraiser.data",
}, {
	target		=> 'indiegogo',
	type		=> 'scrape',
	locale		=> 'en_US',
	time_zone	=> 'America/Los_Angeles',
	file		=> "/indiegogo.non-fundraiser.data",
}, {
	target		=> 'indiegogo',
	type		=> 'scrape',
	locale		=> 'en_US',
	time_zone	=> 'America/Los_Angeles',
	file		=> "/indiegogo.encoding.data",
}, {
	target		=> 'kapilendo',
	type		=> 'scrape',
	locale		=> 'de_DE',
	time_zone	=> 'Europe/Berlin',
	file		=> "/kapilendo.scrape.data",
}, {
	target		=> 'kickstarter',
	type		=> 'scrape',
	locale		=> 'en_US',
	time_zone	=> 'America/New_York',
	file		=> "/kickstarter.scrape.data",
}, {
	target		=> 'seedmatch',
	type		=> 'scrape',
	locale		=> 'de_DE',
	time_zone	=> 'Europe/Berlin',
	file		=> "/seedmatch.taxbutler.data",
}, {
	target		=> 'seedmatch',
	type		=> 'scrape',
	locale		=> 'de_DE',
	time_zone	=> 'Europe/Berlin',
	file		=> "/seedmatch.scrape.data",
}, {
	target		=> 'seedmatch',
	type		=> 'scrape',
	locale		=> 'de_DE',
	time_zone	=> 'Europe/Berlin',
	file		=> "/seedmatch.controme-2.data",
}, {
	target		=> 'startnext',
	target		=> 'startnext',
	type		=> 'scrape',
	locale		=> 'de_DE',
	time_zone	=> 'Europe/Berlin',
	file		=> "/startnext.data",
}, {
	target		=> 'startnext',
	target		=> 'startnext',
	type		=> 'scrape',
	locale		=> 'de_DE',
	time_zone	=> 'Europe/Berlin',
	file		=> "/siebdruckatelier.data",
}, {
	target		=> 'startnext',
	target		=> 'startnext',
	type		=> 'scrape',
	locale		=> 'de_DE',
	time_zone	=> 'Europe/Berlin',
	file		=> "/kunst.data",
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
	print " Test for Scraper::Parser module\n\n";
	print "--------------------------------------------------------------------------\n\n";

	foreach ( my $i = 0; $i < @Conf; $i++ ) {

		printf( "%2s: %-24s%-64s\n", $i, $Conf[$i]->{target}, $Conf[$i]->{file} );
	}

	print "\n";

}

sub validate_choice {

	my $choice = int shift;

	if ( $choice >= 0 && $choice < @Conf ) {

		return 1;
	}

	return 0;
}

sub do_choice {

	my $choice = int shift;

	my %params = %{$Conf[$choice]};

	$params{file} = $config_parameters->{test_data} . $params{file};

	my $parser = Scraper::Parser->new( $config_parameters, undef, \%params )
		or die "$0 Scraper::Parser->new() failed";

	my $result = $parser->run();

	if ( $result->is_error ) {

		print $result->message . "\n";
	}
	else {
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
