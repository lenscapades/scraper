#!/usr/bin/perl -w

use lib "$ENV{HOME}/perl5/lib/perl5";
use lib "$ENV{HOME}/scraper/lib";

use strict;
use warnings;

use Lib::Config;

my $config = Lib::Config->new( qw(Explorer) )
	or die "$0 Lib::Config->new() failed";

my $config_parameters = $config->get();

use Lib::Info::Explorer;

my $info = Lib::Info::Explorer->new( $config_parameters )
	or die "$0 Lib::Info::Explorer->new() failed";

use Lib::Database::Explorer;

my $database = Lib::Database::Explorer->new( $config_parameters )
	or die "$0 Lib::Database::Explorer->new() failed";

use Lib::Proxy;

my $proxy = Lib::Proxy->new( $config_parameters, $info )
	or die "$0 Lib::Proxy->new() failed";

use Lib::Get;

my @Conf = ( {
	target		=> 'bergfuerst',
	type		=> 'explore',
	request		=> 'https://de.bergfuerst.com/investitionsmoeglichkeiten',
	page_number	=> -1,
	referer		=> 'https://de.bergfuerst.com',
	locale		=> 'de_DE',
	time_zone	=> 'Europe/Berlin',
	autosave	=> 1,
}, {
	target		=> 'companisto', 
	id		=> 100,
	type		=> 'explore', 
	request		=> 'https://www.companisto.com/de/investments',
	page_number	=> -1,
	referer		=> 'https://www.companisto.com',
	locale		=> 'de_DE',
	time_zone	=> 'Europe/Berlin',
	autosave	=> 1,
}, {
	target		=> 'deutsche-mikroinvest',
	id		=> 120,
	type		=> 'explore',
	request		=> 'https://www.deutsche-mikroinvest.de/investmentangebote',
	page_number	=> -1,
	referer		=> 'https://www.deutsche-mikroinvest.de',
	time_zone	=> 'Europe/Berlin',
	autosave	=> 1,
}, {
	target		=> 'exporo',
	id		=> 150,
	type		=> 'explore',
	request		=> 'https://exporo.de/projekte',
	page_number	=> -1,
	referer		=> 'https://exporo.de',
	locale		=> 'de_DE',
	time_zone	=> 'Europe/Berlin',
	autosave	=> 1,
}, {
	target		=> 'indiegogo',
	id		=> 93,
	type		=> 'explore',
	request		=> 'https://www.indiegogo.com/private_api/explore?filter_category=Other+Community+Projects&filter_funding=&filter_percent_funded=&filter_quick=new&filter_status=&or_filter_regular_campaign_active=true&per_page=12&pg_num=$page=1',
	page_number	=> 1,
	referer		=> 'https://www.indiegogo.com/explore/other-community-projects?quick_filter=trending&location=everywhere&project_type=all&percent_funded=all&goal_type=all&more_options=false&status=all',
	locale		=> 'en_US',
	time_zone	=> 'America/Los_Angeles',
	autosave	=> 1,
}, {
	target		=> 'kapilendo',
	id		=> 140,
	type		=> 'explore',
	request		=> 'https://www.kapilendo.de/projekte',
	page_number	=> -1,
	referer		=> 'https://www.kapilendo.de',
	locale		=> 'de_DE',
	time_zone	=> 'Europe/Berlin',
	autosave	=> 1,
}, {
	target		=> 'kickstarter',
	id		=> 12,
	type		=> 'explore',
	request		=> 'https://www.kickstarter.com/discover/advanced?google_chrome_workaround&category_id=12&sort=newest&seed=2480607&page=1',
	page_number	=> 1,
	referer		=> 'https://www.kickstarter.com/discover/categories/games?sort=newest',
	locale		=> 'en_US',
	time_zone	=> 'America/New_York',
	autosave	=> 1,
}, {
	target		=> 'seedmatch',
	id		=> 130,
	type		=> 'explore',
	request		=> 'https://www.seedmatch.de/startups',
	page_number	=> -1,
	referer		=> 'https://www.seedmatch.de',
	locale		=> 'de_DE',
	time_zone	=> 'Europe/Berlin',
	autosave	=> 1,
}, {
	target		=> 'startnext',
	id		=> 38,
	type		=> 'explore',
	request		=> 'https://www.startnext.com/templates/platforms/startnext/snippets/project/list/projects.php?lang=de&count=12&q=invention/fundings/crowdindex-d/10/4124&pageNr=$page=0&topic=tyNavigationTopicID_4301&areas=content&page=',
	page_number	=> 0,
	referer		=> 'https://www.startnext.com/Projekte.html',
	locale		=> 'de_DE',
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

sub get_choice {

	my $choice = <>;

	chomp $choice;

	return $choice;
}

sub show_choices {

	system( "clear" );

	print "--------------------------------------------------------------------------\n\n";
	print " Test of Explorer::Parser and Lib::Get module\n\n";
	print "--------------------------------------------------------------------------\n\n";

	foreach ( my $i = 0; $i < @Conf; $i++ ) {

		printf( "%2s: %s\n", $i, $Conf[$i]->{target} );
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
		{ proxy	=> 1, agent => 1, daemon => qw(Explorer) }
	);

	my $response = $get->get_response( $target );

	if ( !$response->is_error ) {

		my $result = $get->get_content( $response->content() );

		print "--------------------------------------------------------------------------\n\n";

		if ( $result->is_error ) {

			print $result->message. "\n";
		}
		else {
			my $data = $result->content();

			if ( scalar @$data ) {

				print "Get results\n\n";

				if ( my $extra = $result->extra ) {

					print "Entries per page: $extra->{per_page}\n";
				}

				$get->print( $data );

#				print "\n";
#				print "Query results\n\n";

#				$database->update_database( $target, $data );

#				$get->print(
#					$database->select_campaign_data( $data, [ 'name' ] )
#				);
			}
			else {
				print "Could not find any campaigns.\n";
			}
		}

		print "\n";
		print "--------------------------------------------------------------------------\n";
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
