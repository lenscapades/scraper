package Proxy::Update;

use Lib::Datetime;

use Lib::Get;

use Lib::Database::Proxy;

use Data::Dumper;

sub new {

	my $class = shift;

	my $self = {};

	bless( $self, $class );

	$self->{config}	= shift
		or die __PACKAGE__ . "->new() missing config data";

	$self->{logging} = shift
		or die __PACKAGE__ . "->new() missing logging object";

	$self->{info} = shift
		or die __PACKAGE__ . "->new() missing info object";

	$self->{datetime} = Lib::Datetime->new(

				$self->{config}

        	) or die __PACKAGE__ . "->new() Lib::Datetime->new() failed";

	$self->{get} = Lib::Get->new(

				$self->{config},

				$self->{logging}, {

					proxy => 1,

					agent => 1,

					logging => undef,

					daemon => qw(Proxy)
				}

		) or die __PACKAGE__ . "->new() Lib::Get->new() failed";

	$self->{database} = Lib::Database::Proxy->new(

				$self->{config}

        	) or die __PACKAGE__ . "->new() Lib::Database::Proxy->new() failed";

	return $self;
}

sub run {

	my $self = shift;

	my $update_date = $self->get_update_date();

	my $proxy = $self->{database}->get_unchecked_proxy( $update_date, $self->{config}->{update_age} );

	if ( $proxy ) {

		$self->{logging}->entry( 2, "Checking $proxy" );

		$self->check( $proxy );
	}
	else {

		$self->reset_update_date();
	}
}

sub get_update_date {

	my $self = shift;

	my $update_date = $self->{info}->get_update_date();

	if ( defined( $update_date ) && $update_date ) {

		return $update_date;
	}

	$update_date = $self->{datetime}->long();

	$self->{info}->set_update_date( $update_date );

	return $update_date;
}

sub reset_update_date {

	my $self = shift;

	$self->{info}->reset_update_date();

	$self->{info}->set_task( "sleep" );
}

sub get_ip_targets {

	my $self = shift;

	my $entries = $self->{info}->get_targets( qw(ip) );

	if ( !defined( $entries) || !scalar( @$entries ) ) {

		if ( my $ip_targets = $self->{config}->{ip_targets} ) {

			my @targets = @$ip_targets;

			foreach my $target ( @targets ) {

				push( @$entries, $self->factory_ip_target( qw(check), $target ) );
			}

			$self->{info}->set_targets( qw(ip), $entries );
		}
		else {
			die __PACKAGE__ . "->get_ip_targets() missing ip service targets configuration data";
		}
	}

	return $entries;
}

sub factory_ip_target {

	my $self = shift;

	my $type = shift
		or die __PACKAGE__ . "->factory_ip_target() missing argument";

	my $target = shift
		or die __PACKAGE__ . "->factory_ip_target() missing argument";

	my %entry = ();

	if ( $target->{uri} =~ /^http(s){0,1}:\/\/(www\.){0,1}([^\.]+)/ ) {

		$entry{target} = $3;

		$entry{type} = $type;

		$entry{request}	= $target->{uri};

		if ( defined( $target->{referer} ) ) {

			$entry{referer}	= $target->{referer};
		}
		else {
			$entry{referer}	= 'https://www.google.de';
		}
	}

	return \%entry;
}

sub do_check {

	my $self = shift;

	my $proxy = shift
		or die __PACKAGE__ . "->do_check() missing argument";

	my $ip_targets = $self->get_ip_targets();

	my $ip_target = $ip_targets->[ int rand @$ip_targets ];

	$ip_target->{proxy} = $proxy;

	my $message = undef;

	my $response = $self->{get}->get_response( $ip_target );

	if ( !$response->is_error ) {

		my $result = $self->{get}->get_content( $response->content() );

		if ( !$result->is_error ) {

			if ( my $content = $result->content() ) {

				my ( $ip, $port ) = split( ':', $proxy );

				if ( !defined( $content->[0] ) || $content->[0]->{ip} ne $ip ) {

					$message = "Could not parse data";
				}
			}
			else {

				$message = "No data";
			}
		}
		else {
			$message = $result->message;

		}
	}
	else {
		$message = $response->message;
	}

	if ( defined( $message ) ) {

		$self->{logging}->entry( 3, "Test on " . $ip_target->{request} . " failed" );

		$self->{logging}->entry( 4, $message );

		return 0;
	}
	else {
		$self->{logging}->entry( 3, "Test on " . $ip_target->{request} . " succeeded" );

		return 1;
	}
}

sub check {

	my $self = shift;

	my $proxy = shift
		or die __PACKAGE__ . "->get() missing_argument";

	if ( $self->do_check( $proxy ) ) {

		my $now = $self->{datetime}->long();

		$self->{database}->update_proxy_result( $proxy, $now, 1 );

		$self->{logging}->entry( 2, "Test passed" );
	}
	else {
		my $now = $self->{datetime}->long();

		$self->{database}->update_proxy_result( $proxy, $now, 0 );

		$self->{logging}->entry( 2, "Test failed" );
	}
}

1;
