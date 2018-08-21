#!/usr/bin/perl -w
use lib "$ENV{HOME}/perl5/lib/perl5";
use lib "$ENV{HOME}/scraper/lib";
use strict;
use warnings;
use Lib::Config;

my $config = new Lib::Config( qw(Proxy) )
	or die "$0 Lib::Config->new() failed";

my $config_parameters = $config->get();

my @Conf = ( {
	target	=> 'sslproxies',
	type	=> 'explore',
	file	=> "/sslproxies.explore.data",
}, {
	target	=> 'sslproxies',
	type	=> 'scrape',
	file	=> "/sslproxies.scrape.data",
}, {
	target	=> 'freeproxylists',
	type	=> 'explore',
	file	=> "/freeproxylists.explore.data",
}, {
	target	=> 'freeproxylists',
	type	=> 'scrape',
	file	=> "/freeproxylists.scrape.data",
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
	print " Proxy::Parser test\n\n";
	print "--------------------------------------------------------------------------\n\n";
	print " 0: sslproxies, explore            1: sslproxies, scrape\n";
	print " 2: freeproxylists, explore        3: freeproxylists, scrape\n";
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

	my $parser;

	my %params = %{$Conf[$choice]};

	$params{file} = $config_parameters->{test_data} . $params{file};

	use Proxy::Parser;

	$parser = new Proxy::Parser(
			$config_parameters,
			undef,
			\%params,
		)
		or die "$0 Proxy::Parser->new() failed";

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
