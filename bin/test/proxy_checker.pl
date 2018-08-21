#!/usr/bin/perl -w

use lib "$ENV{HOME}/perl5/lib/perl5";
use lib "$ENV{HOME}/scraper/lib";

use strict;
use warnings;

use Data::Dumper;

use Lib::Config;
use Lib::Logging;
use Lib::Get;

my $config = Lib::Config->new( qw(Proxy) )
	or die "$0 Lib::Config->new() failed";

my $config_parameters = $config->get();

my $logging = Lib::Logging->new( $config_parameters, { verbose => undef } )
	or die "$0 Lib::Logging->new() failed";

$logging->caller( 'Checker' );

use Lib::Info::Proxy;

my $info = Lib::Info::Proxy->new( $config_parameters, { target => 'sslproxies' } )
	or die "$0 Lib::Info::Proxy->new() failed";

use Lib::Proxy;

my $proxy = Lib::Proxy->new( $config_parameters, $info )
	or die "$0 Lib::Proxy->new() failed";

my $use_proxy = 1;

my $proxy_addr = undef;

my @Conf = ( {
	target		=> 'astrill',
	type		=> 'check',
	request		=> 'https://www.astrill.com/what-is-my-ip-address.php',
	referer		=> 'https://www.google.de',
}, {
	target		=> 'bnl',
	type		=> 'check',
	request		=> 'https://www.bnl.gov/itd/webapps/checkip.asp',
	referer		=> 'https://www.google.de',
}, {
	target		=> 'etes',
	type		=> 'check',
	request		=> 'https://www.etes.de/service/ip-check/',
	referer		=> 'https://www.google.de',
}, {
	target		=> 'expressvpn',
	type		=> 'check',
	request		=> 'https://www.expressvpn.com/what-is-my-ip',
	referer		=> 'https://www.google.de',
}, {
	target		=> 'hide',
	type		=> 'check',
	request		=> 'https://hide.me/de/check',
	referer		=> 'https://www.google.de',
}, {
	target		=> 'iplocation',
	type		=> 'check',
	request		=> 'https://www.iplocation.net/find-ip-address',
	referer		=> 'https://www.google.de',
	autosave	=> 1,
}, {
	target		=> 'showip',
	type		=> 'check',
	request		=> 'https://showip.net/',
	referer		=> 'https://www.google.de',
}, {
	target		=> 'wieistmeineip',
	type		=> 'check',
	request		=> 'https://wieistmeineip.de/',
	referer		=> 'https://www.google.de',
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

	if ( $use_proxy ) {

		$proxy_addr = $proxy->get_proxy();
		print " Proxy $proxy_addr\n\n";
	}
	print " 0: astrill\n";
	print " 1: bnl.gov\n";
	print " 2: etes\n";
	print " 3: expressvpn\n";
	print " 4: hide.me\n";
	print " 5: iplocation\n";
	print " 6: showip\n";
	print "\n";
}

sub validate_choice {

	my $choice = int shift;

	if ( $choice >= 0 && $choice <= 6 ) {

		return 1;
	}

	return 0;
}

sub do_choice {

	my $get = Lib::Get->new(
		$config_parameters,
		$logging,
		{ proxy	=> $use_proxy, agent => 1, logging => undef, daemon => qw(Proxy) }
	);

	my $choice = int shift;

	my %params = %{$Conf[$choice]};

	if ( $use_proxy ) {

		$params{proxy} = $proxy_addr;
	}
	else {

		$params{proxy} = undef;
	}

	my $response = $get->get_response( \%params );

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
