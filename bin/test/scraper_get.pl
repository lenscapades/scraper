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

my @Conf = ( {
	target		=> 'bergfuerst',
	type		=> 'scrape',
	request		=> 'https://de.bergfuerst.com/immobilien/soleada',
	referer		=> 'https://de.bergfuerst.com/investitionsmoeglichkeiten',
	time_zone	=> 'Europe/Berlin',
	autosave	=> 1,
}, {
	target		=> 'bergfuerst',
	type		=> 'scrape',
	request		=> 'https://de.bergfuerst.com/immobilien/leipzig-holzhaeuser-strasse',
	referer		=> 'https://de.bergfuerst.com/investitionsmoeglichkeiten',
	time_zone	=> 'Europe/Berlin',
	autosave	=> 1,
}, {
	target		=> 'bergfuerst',
	type		=> 'scrape',
	request		=> 'https://de.bergfuerst.com/immobilien/taka-tuka-land',
	referer		=> 'https://de.bergfuerst.com/investitionsmoeglichkeiten',
	time_zone	=> 'Europe/Berlin',
	autosave	=> 0,
}, {
	target		=> 'companisto', 
	type		=> 'scrape', 
	request		=> 'https://www.companisto.com/de/investment/ase',
	referer		=> 'https://www.companisto.com/de/investments',
	time_zone	=> 'Europe/Berlin',
	autosave	=> 1,
}, {
	target		=> 'companisto', 
	type		=> 'scrape', 
	request		=> 'https://www.companisto.com/de/investment/ambico',
	referer		=> 'https://www.companisto.com/de/investments',
	time_zone	=> 'Europe/Berlin',
	autosave	=> 0,
}, {
	target		=> 'companisto', 
	type		=> 'scrape', 
	request		=> 'https://www.companisto.com/de/investment/horando',
	referer		=> 'https://www.companisto.com/de/investments',
	time_zone	=> 'Europe/Berlin',
	autosave	=> 1,
}, {
	target		=> 'companisto', 
	type		=> 'scrape', 
	request		=> 'https://www.companisto.com/de/investment/4040-return',
	referer		=> 'https://www.companisto.com/de/investments',
	time_zone	=> 'Europe/Berlin',
	autosave	=> 1,
}, {
	target		=> 'deutsche-mikroinvest',
	type		=> 'scrape',
	request		=> 'https://www.deutsche-mikroinvest.de/foodcontrack',
	referer		=> 'https://www.deutsche-mikroinvest.de/investmentangebote',
	time_zone	=> 'Europe/Berlin',
	autosave	=> 0,
}, {
	target		=> 'deutsche-mikroinvest',
	type		=> 'scrape',
	request		=> 'https://www.deutsche-mikroinvest.de/sternback',
	referer		=> 'https://www.deutsche-mikroinvest.de/investmentangebote',
	time_zone	=> 'Europe/Berlin',
	autosave	=> 1,
}, {
	target		=> 'exporo',
	type		=> 'scrape',
	request		=> 'https://exporo.de/projekt/porta-nova',
	referer		=> 'https://exporo.de/projekte',
	time_zone	=> 'Europe/Berlin',
	autosave	=> 0,
}, {
	target		=> 'exporo',
	type		=> 'scrape',
	request		=> 'https://exporo.de/projekt/joliot-curie-platz',
	referer		=> 'https://exporo.de/projekte',
	time_zone	=> 'Europe/Berlin',
	autosave	=> 0,
}, {
	target		=> 'exporo',
	type		=> 'scrape',
	request		=> 'https://exporo.de/projekt/christmas-critters',
	referer		=> 'https://exporo.de/projekte',
	time_zone	=> 'Europe/Berlin',
	autosave	=> 0,
}, {
	target		=> 'indiegogo',
	type		=> 'scrape',
	request		=> 'https://www.indiegogo.com/projects/the-evrythng-bag-iphone-laptop',
	referrer	=> 'https://www.indiegogo.com/explore/trending?quick_filter=trending&location=everywhere&project_type=all&percent_funded=all&goal_type=all&more_options=false&status=all',
	time_zone	=> 'America/Los_Angeles',
	autosave	=> 1,
}, {
	target		=> 'indiegogo',
	type		=> 'scrape',
	request		=> 'https://www.indiegogo.com/projects/mate-the-coolest-ebike-ever-bicycle',
	referrer	=> 'https://www.indiegogo.com/explore/transportation?quick_filter=trending&location=everywhere&project_type=all&percent_funded=all&goal_type=all&more_options=false&status=all',
	time_zone	=> 'America/Los_Angeles',
	autosave	=> 0,
}, {
	target		=> 'indiegogo',
	type		=> 'scrape',
	request		=> 'https://www.indiegogo.com/projects/vehicle-security-system-device-mobile',
	referrer	=> 'https://www.indiegogo.com/explore/transportation?quick_filter=trending&location=everywhere&project_type=all&percent_funded=all&goal_type=all&more_options=false&status=all',
	time_zone	=> 'America/Los_Angeles',
	autosave	=> 1,
}, {
	target		=> 'indiegogo',
	type		=> 'scrape',
	request		=> 'https://www.indiegogo.com/projects/association-cancer-support-services-help',
	referrer	=> 'https://www.indiegogo.com/explore/human-rights?quick_filter=trending&location=everywhere&project_type=all&percent_funded=all&goal_type=all&more_options=false&status=all',
	time_zone	=> 'America/Los_Angeles',
	autosave	=> 1,
}, {
	target		=> 'indiegogo',
	type		=> 'scrape',
	request		=> 'https://www.indiegogo.com/projects/gioconda-connection-art-health',
	referrer	=> 'https://www.indiegogo.com/explore/art?quick_filter=trending&location=everywhere&project_type=all&percent_funded=all&goal_type=all&more_options=false&status=all',
	time_zone	=> 'America/Los_Angeles',
	autosave	=> 1,
}, {
	target		=> 'indiegogo',
	type		=> 'scrape',
	request		=> 'https://www.indiegogo.com/projects/the-oreous-pillow#/',
	referrer	=> 'https://www.indiegogo.com/explore/home?quick_filter=trending&location=everywhere&project_type=all&percent_funded=all&goal_type=all&more_options=false&status=all',
	time_zone	=> 'America/Los_Angeles',
	autosave	=> 1,
}, {
	target		=> 'indiegogo',
	type		=> 'scrape',
	request		=> 'https://www.indiegogo.com/projects/norwester-a-watch-made-to-be-worn-anytime-watches--2',
	referrer	=> 'https://www.indiegogo.com/explore/fashion-wearables?quick_filter=trending&location=everywhere&project_type=all&percent_funded=all&goal_type=all&more_options=false&status=all',
	time_zone	=> 'America/Los_Angeles',
	autosave	=> 1,
}, {
	target		=> 'indiegogo',
	type		=> 'scrape',
	request		=> 'https://www.indiegogo.com/projects/i-am-trying-to-break-your-heart-short-film-music',
	referrer	=> 'https://www.indiegogo.com/explore/film?quick_filter=trending&location=everywhere&project_type=all&percent_funded=all&goal_type=all&more_options=false&status=all',
	time_zone	=> 'America/Los_Angeles',
	autosave	=> 1,
}, {
	target		=> 'kapilendo',
	target		=> 'kapilendo',
	type		=> 'scrape',
	request		=> 'https://www.kapilendo.de/projekte/00250ad5-0781-4d3f-87b5-0c7cd40acae7',
	referer		=> 'https://www.kapilendo.de/projekte',
	time_zone	=> 'Europe/Berlin',
	autosave	=> 0,
}, {
	target		=> 'kapilendo',
	type		=> 'scrape',
	request		=> 'https://www.kapilendo.de/projekte/8b2db086-74f9-4c87-8379-f2223bad03f4',
	referer		=> 'https://www.kapilendo.de/projekte',
	time_zone	=> 'Europe/Berlin',
	autosave	=> 0,
}, {
	target		=> 'kickstarter',
	type		=> 'scrape',
	request		=> 'https://www.kickstarter.com/projects/1493786635/matheta-dance-premiere-performance?ref=category_newest',
	referer		=> 'https://www.kickstarter.com/discover/categories/dance?sort=newest',
	time_zone	=> 'America/New_York',
	autosave	=> 1,
}, {
	target		=> 'kickstarter',
	type		=> 'scrape',
	request		=> 'https://www.kickstarter.com/projects/1463648081/xo-audio-enclosures?ref=category_newest',
	referer		=> 'https://www.kickstarter.com/discover/categories/design?sort=newest',
	time_zone	=> 'America/New_York',
	autosave	=> 1,
}, {
	target		=> 'kickstarter',
	type		=> 'scrape',
	request		=> 'https://www.kickstarter.com/projects/196655077/luxury-handmade-leather-cases-and-covers-for-iphon?ref=category_newest',
	referer		=> 'https://www.kickstarter.com/discover/categories/design?sort=newest',
	time_zone	=> 'America/New_York',
	autosave	=> 1,
}, {
	target		=> 'kickstarter',
	type		=> 'scrape',
	request		=> 'https://www.kickstarter.com/projects/778947199/strain-wars-the-collage-deck?ref=category_newest',
	referer		=> 'https://www.kickstarter.com/discover/categories/games?sort=newest',
	time_zone	=> 'America/New_York',
	autosave	=> 1,
}, {
	target		=> 'kickstarter',
	type		=> 'scrape',
	request		=> 'https://www.kickstarter.com/projects/976436033/vegan-show-cooking?ref=category_newest',
	referer		=> 'https://www.kickstarter.com/discover/categories/food?sort=newest',
	time_zone	=> 'America/New_York',
	autosave	=> 0,
}, {
	target		=> 'kickstarter',
	type		=> 'scrape',
	request		=> 'https://www.kickstarter.com/projects/324804347/son-of-the-prisonland-epic-fantasy-novel?ref=category_newest',
	referer		=> 'https://www.kickstarter.com/discover/categories/publishing?sort=newest',
	time_zone	=> 'America/New_York',
	autosave	=> 0,
}, {
	target		=> 'kickstarter',
	type		=> 'scrape',
	request		=> 'https://www.kickstarter.com/projects/harebrainedinc/shit-for-brains?ref=category_newest',
	referer		=> 'https://www.kickstarter.com/discover/categories/games?sort=newest',
	time_zone	=> 'America/New_York',
	autosave	=> 1,
}, {
	target		=> 'kickstarter',
	type		=> 'scrape',
	request		=> 'https://www.kickstarter.com/projects/1653333139/torn-letters-from-ypres?ref=category_newest',
	referer		=> 'https://www.kickstarter.com/discover/categories/fiction?sort=newest',
	time_zone	=> 'America/New_York',
	autosave	=> 1,
}, {
	target		=> 'kickstarter',
	type		=> 'scrape',
	request		=> 'https://www.kickstarter.com/projects/loresmyth/remarkable-inns-and-their-drinks-the-ultimate-gms?ref=category_newest',
	referer		=> 'https://www.kickstarter.com/discover/categories/games?sort=newest',
	time_zone	=> 'America/New_York',
	autosave	=> 0,
}, {
	target		=> 'kickstarter',
	type		=> 'scrape',
	request		=> 'https://www.kickstarter.com/projects/4711/lorem-ipsum?ref=category_newest',
	referer		=> 'https://www.kickstarter.com/discover/categories/games?sort=newest',
	time_zone	=> 'America/New_York',
	autosave	=> 0,
}, {
	target		=> 'kickstarter',
	type		=> 'scrape',
	request		=> 'https://www.kickstarter.com/projects/1657941665/the-spiraletm-wine-glass?ref=category_newest',
	referer		=> 'https://www.kickstarter.com/discover/categories/design?sort=newest',
	time_zone	=> 'America/New_York',
	autosave	=> 0,
}, {
	target		=> 'kickstarter',
	type		=> 'scrape',
	request		=> 'https://www.kickstarter.com/projects/297497223/mrmisocki-volume-2-comic-inspired-solo-socks?ref=category_newest',
	referer		=> 'https://www.kickstarter.com/discover/categories/fashion?sort=newest',
	time_zone	=> 'America/New_York',
	autosave	=> 1,
}, {
	target		=> 'kickstarter',
	type		=> 'scrape',
	request		=> 'https://www.kickstarter.com/projects/1388037818/bbc-support-for-block-b-in-sf?ref=category_newest',
	referer		=> 'https://www.kickstarter.com/discover/categories/art?sort=newest',
	time_zone	=> 'America/New_York',
	autosave	=> 1,
}, {
	target		=> 'seedmatch',
	type		=> 'scrape',
	request		=> 'https://www.seedmatch.de/startups/askania',
	referer		=> 'https://www.seedmatch.de/startups',
	time_zone	=> 'Europe/Berlin',
	autosave	=> 0,
}, {
	target		=> 'seedmatch',
	type		=> 'scrape',
	request		=> 'https://www.seedmatch.de/startups/taxbutler',
	referer		=> 'https://www.seedmatch.de/startups',
	time_zone	=> 'Europe/Berlin',
	autosave	=> 0,
}, {
	target		=> 'seedmatch',
	type		=> 'scrape',
	request		=> 'https://www.seedmatch.de/startups/controme-2',
	referer		=> 'https://www.seedmatch.de/startups',
	time_zone	=> 'Europe/Berlin',
	autosave	=> 0,
}, {
	target		=> 'seedmatch',
	type		=> 'scrape',
	request		=> 'https://www.seedmatch.de/startups/rodos-biotarget',
	referer		=> 'https://www.seedmatch.de/startups',
	time_zone	=> 'Europe/Berlin',
	autosave	=> 0,
}, {
	target		=> 'seedmatch',
	type		=> 'scrape',
	request		=> 'https://www.seedmatch.de/startups/another-one-bites-the-dust',
	referer		=> 'https://www.seedmatch.de/startups',
	time_zone	=> 'Europe/Berlin',
	autosave	=> 0,
}, {
	target		=> 'startnext',
	type		=> 'scrape',
	request		=> 'https://www.startnext.com/mein-traum-von-einem-fantasy-epos',
	referer		=> 'https://www.startnext.com/Projekte.html',
	time_zone	=> 'Europe/Berlin',
	autosave	=> 0,
}, {
	target		=> 'startnext',
	type		=> 'scrape',
	request		=> 'https://www.startnext.com/concordia-saison-shirt-16-17',
	referer		=> 'https://www.startnext.com/Projekte.html',
	time_zone	=> 'Europe/Berlin',
	autosave	=> 0,
}, {
	target		=> 'startnext',
	type		=> 'scrape',
	request		=> 'https://www.startnext.com/properplace',
	referer		=> 'https://www.startnext.com/Projekte.html',
	time_zone	=> 'Europe/Berlin',
	autosave	=> 0,
}, {
	target		=> 'startnext',
	type		=> 'scrape',
	request		=> 'https://www.startnext.com/mooobiee',
	referer		=> 'https://www.startnext.com/Projekte.html',
	time_zone	=> 'Europe/Berlin',
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
