package Lib::Proxy;

=pod

=head1 NAME

Lib::Proxy - Interface to proxy database

=head1 SYNOPSIS

	use Lib::Proxy;

	my $proxy = Lib::Proxy->new();

	$proxy->get_proxy();

	$proxy->update_proxy();

=head1 DESCRIPTION



=cut

use Lib::Datetime;

use Lib::Database::Proxy;

use Data::Dumper;

sub new {

	my $class = shift;

	my $self = {};

	bless( $self, $class );

	$self->{config} = shift
		or die __PACKAGE__ . "->new() missing config data";

	$self->{info} = shift
		or die __PACKAGE__ . "->new() missing info object";

	$self->{datetime} = Lib::Datetime->new( $self->{config} )
		or die __PACKAGE__ . "->new() Lib::Datetime->new() failed";

	$self->{database} = Lib::Database::Proxy->new( $self->{config} )
		or die __PACKAGE__ . "->new() Lib::Database::Proxy->new() failed";

	return $self;
}

=head1 METHODS

=head2 get_proxies

=cut

sub get_proxies {

	my $self = shift;

	return $self->{database}->get_proxies();
}

=head2 get_proxy

=cut

sub get_proxy {

	my $self = shift;

	my $proxies = $self->{info}->get_proxies();

	if ( !defined( $proxies ) || !scalar( @$proxies ) ) {

		$proxies = $self->{database}->get_proxies();
	}

	if ( defined( $proxies ) && @$proxies ) {

		my $proxy = shift @$proxies;

		$self->{info}->set_proxies( $proxies );

		return $proxy->{ip} . ':' . $proxy->{port};
	}

	return undef;
}

=head2 update_proxy

=cut

sub update_proxy {

	my $self = shift;

	my $proxy = shift;

	if ( !defined( $proxy ) ) {

		return;
	}

	my $result = shift;

	if ( !defined( $result ) ) {

		die __PACKAGE__ . "->update_proxy() missing argument";
	}

	my $now = $self->{datetime}->long();

	$self->{database}->update_proxy_result( $proxy, $now, $result );
}

1;
