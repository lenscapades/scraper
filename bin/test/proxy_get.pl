#!/usr/bin/perl -w

use lib "$ENV{HOME}/perl5/lib/perl5";
use lib "$ENV{HOME}/scraper/lib";

use strict;
use warnings;

use Data::Dumper;

use Lib::Config;

my $config = Lib::Config->new( qw(Proxy) )
	or die "$0 Lib::Config->new() failed";

my $config_parameters = $config->get();

use Lib::Get;

my $get = Lib::Get->new(
	$config_parameters,
	undef,
	{ proxy	=> undef, agent => 1, daemon => qw(Proxy) }
);

my @Conf = ( {
	target		=> 'sslproxies',
	type		=> 'explore',
	request		=> 'https://www.sslproxies.org/',
	referer		=> 'https://www.google.de',
	autosave	=> 0,
}, {
	target		=> 'sslproxies',
	type		=> 'scrape',
	request		=> 'https://www.sslproxies.org/',
	referer		=> 'https://www.google.de',
	autosave	=> 1,
}, {
	target		=> 'freeproxylists',
	type		=> 'explore',
	request		=> 'http://www.freeproxylists.com/elite.html',
	referer		=> 'https://www.google.de',
	autosave	=> 0,
}, {
	target		=> 'freeproxylists',
	type		=> 'scrape',
	request		=> 'http://www.freeproxylists.com/load_elite_d1492437021.html',
	referer		=> 'https://www.google.de',
	autosave	=> 0,
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
	print " Lib::Get and Proxy::Parser test\n\n";
	print "--------------------------------------------------------------------------\n\n";
	print " 0: sslproxies, explore\n";
	print " 1: sslproxies, scrape\n";
	print " 2: freeproxylists, explore\n";
	print " 3: freeproxylists, scrape\n";
	print "\n";

}

sub validate_choice {

	my $choice = int shift;

	if ( $choice >= 0 && $choice < 4 ) {

		return 1;
	}

	return 0;
}

sub do_choice {

	my $choice = int shift;

	my $response = $get->get_response( $Conf[$choice] );

	if ( !$response->is_error ) {

		my $result = $get->get_content( $response->content() );

		if ( $result->is_error ) {

			print $result->message. "\n";
		}
		else {
		
			$get->print( $result->content() );
		}
	}
	else {

		print $response->message . "\n";
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
