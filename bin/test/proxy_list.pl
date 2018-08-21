#!/usr/bin/perl -w

use lib "$ENV{HOME}/perl5/lib/perl5";
use lib "$ENV{HOME}/scraper/lib";

use strict;
use warnings;

use Lib::Config;
use Lib::Info::Proxy;
use Lib::Proxy;

use Data::Dumper;

my $config = new Lib::Config( qw(Proxy) )
        or die "$0 Lib::Config->new() failed";

my $config_parameters = $config->get();

my $info = new Lib::Info::Proxy(

		$config_parameters, {

			target => 'sslproxies' 
		}

        ) or die "$0 Lib::Info::Proxy->new() failed";

my $proxy = new Lib::Proxy(
	$config_parameters,
	$info,
)
or die "$0 Lib::Proxy->new() failed";

my $proxy_list = $proxy->get_proxies();

print @$proxy_list . "\n";

foreach my $item ( @$proxy_list ) {

	printf( "%20s:%-6s | %8.2f | %8.2f | %5d | %5d \n",
		$item->{ip}, $item->{port},
		$item->{score},
		$item->{weight},
		$item->{has_succeeded},
		$item->{has_failed}
	);
}
