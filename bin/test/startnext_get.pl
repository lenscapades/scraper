#!/usr/bin/perl -w

use lib "$ENV{HOME}/perl5/lib/perl5";
use lib "$ENV{HOME}/scraper/lib";

use strict;
use warnings;

use Lib::Config;

use Scraper::Parser;

my $config = Lib::Config->new( qw(Scraper) )
	or die "$0 Lib::Config->new() failed";

my $config_parameters = $config->get();

use Lib::Info::Scraper;

my $info = Lib::Info::Scraper->new( $config_parameters, { target => 'new' } )
	or die "$0 Lib::Info::Scraper->new() failed";

use Lib::Proxy;

my $proxy = Lib::Proxy->new( $config_parameters, $info )
	or die "$0 Lib::Proxy->new() failed";

use Lib::Get;

my @Conf = ();

my @uris = (
	'https://www.indiegogo.com/projects/bottoms-up-true-tales-of-hitting-rock-bottom-comics-drugs',
);

@uris = reverse @uris;

foreach my $uri ( @uris ) {

@Conf = ( {
	target		=> 'indiegogo',
	type		=> 'scrape',
	request		=> $uri,
	referer		=> 'https://www.startnext.com/Projekte.html',
	time_zone	=> 'Europe/Berlin',
	autosave	=> 1,
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

}

sub get_choice {

	my $choice = <>;

	chomp $choice;

	return $choice;
}

sub show_choices {

	system( "clear" );

	print "--------------------------------------------------------------------------\n\n";
	print " Test for Scraper::Parser and Lib::Get modules\n\n";
	print "--------------------------------------------------------------------------\n\n";

	foreach ( my $i = 0; $i < @Conf; $i++ ) {

		printf( "%2s: %-24s%-64s\n", $i, $Conf[$i]->{target}, $Conf[$i]->{request} );
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

	my $target = $Conf[$choice];

	if ( my $proxy_parameters = $proxy->get_proxy() ) {

		print "\n";
		print "Using proxy $proxy_parameters\n\n";

		$target->{proxy} = $proxy_parameters;
	}

	my $get = Lib::Get->new(
		$config_parameters,
		undef,
		{ proxy	=> 1, agent => 1, daemon => qw(Scraper) }
	);

	my $response = $get->get_response( $target );

	if ( !$response->is_error ) {

		print $response->message . "\n";

		my $result = $get->get_content( $response->content() );

		if ( $result->is_error ) {

			print $result->message. "\n";
		}
		else {

			print $result->message. "\n";

			if ( my $extra = $result->extra ) {

				print "per page: $extra->{per_page}\n";
			}

			$get->print( $result->content() );
		}
	}
	else {

		print $response->message;

		if ( $response->message =~ /^404/ ) {

			if( $get->validate_not_found( $response->content() ) ) {

				print " (Genuine error page)";
			}
		}

		print "\n";
	}

	undef $get;
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
