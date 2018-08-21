package Proxy::Check;

use Lib::Database::Proxy;

use Lib::Get;

use Lib::Datetime;

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

	$self->{database} = Lib::Database::Proxy->new(

				$self->{config}

        	) or die __PACKAGE__ . "->new() Lib::Database::Proxy->new() failed";

	return $self;
}

sub run {

	my $self = shift;

	my $target = undef;

	if ( my @task = $self->task() ) {

		if ( defined( $task[2] ) ) {

			$self->{logging}->entry( 1,  "Checking proxy $task[3]:$task[4] ..." );

			$self->check( \@task );
		}
	}
}

sub task {

	my $self = shift;

	my @task = $self->{info}->get_task();

	if ( !defined( $task[2] ) ) {

		my $targets = $self->get_targets();

		if( @$targets ) {

			$task[2] = 0;

			$task[3] = $targets->[0]->{ip};

			$task[4] = $targets->[0]->{port};

			$self->{info}->set_task( join( ":", @task ) );
		}
		else {

			$self->set_next_task();

			return undef;
		}
	}

	return @task;
}

sub get_targets {

	my $self = shift;

	my $entries = $self->{info}->get_targets( qw(check) );

	return $entries;
}

sub set_retry_task {

	my $self = shift;

	my @task = $self->{info}->get_task();

	unshift( @task, qw(retry) );

	$self->{info}->set_task( join( ":", @task ) );
}

sub set_skip_task {

	my $self = shift;

	my @task = $self->{info}->get_task();

	unshift( @task, qw(skip) );

	$self->{info}->set_task( join( ":", @task ) );
}

sub set_next_task {

	my $self = shift;

	my @task = $self->{info}->get_task();

	my $target = $self->get_next_target( $task[2] );

	if ( defined( $target ) ) {

		my @next_task = ();

		$next_task[0] = $task[0];

		$next_task[1] = $task[1];

		$next_task[2] = $target;

		my $target_parameters = $self->get_target_parameters( $target );

		$next_task[3] = $target_parameters->{ip};

		$next_task[4] = $target_parameters->{port};

		$self->{info}->set_task( join( ":", @next_task ) );
	}
	else {

		$self->{info}->set_task( qw(sleep) );
	}
}

sub get_next_target {

	my $self = shift;

	my $target = shift;

	if ( !defined( $target ) ) {

		return undef;
		# die __PACKAGE__ . "->get_next_target() missing argument";
	}

	if ( defined( $target ) ) {

		my $entries = $self->{info}->get_targets( qw(check) );

		my $i = int $target;

		if ( $i+1 < @$entries ) {

			return $i+1;
		}
	}

	return undef;
}

sub get_target_parameters {

	my $self = shift;

	my $target = shift;

	if ( !defined( $target ) ) {

		die __PACKAGE__ . "->get_target_parameters() missing argument";
	}

	if ( defined( $target ) ) {

		my $entries = $self->{info}->get_targets( qw(check) );

		my $i = int $target;

		return $entries->[$i];
	}

	return undef;
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

	my $task = shift
		or die __PACKAGE__ . "->do_check() missing argument";

	my $ip_targets = $self->get_ip_targets();

	my $ip_target = $ip_targets->[int rand @$ip_targets];

	my $proxy = $task->[3] . ':' . $task->[4];

	$ip_target->{proxy} = $proxy;

	my $message = undef;

	my $get = Lib::Get->new(

				$self->{config},

				$self->{logging}, {

					proxy => 1,

					agent => 1,

					logging => undef,

					daemon => qw(Proxy)
				}

		) or die __PACKAGE__ . "->new() Lib::Get->new() failed";

	my $response = $get->get_response( $ip_target );

	if ( !$response->is_error ) {

		my $result = $get->get_content( $response->content() );

		if ( !$result->is_error ) {

			my $content = $result->content();

			if ( !defined( $content->[0]->{ip} ) || $content->[0]->{ip} ne $task->[3] ) {

				$message = "Could not parse data";
			}
		}
		else {

			$message = $result->message;
		}
	}
	else {

		$message = $response->message;
	}

	undef $get;

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

	my $task = shift
		or die __PACKAGE__ . "->get() missing_argument";

	if ( $self->do_check( $task ) ) {

		$self->{logging}->entry( 2, "Saving to database" );

		my $target_parameters = $self->get_target_parameters( $task->[2] );

		$target_parameters->{has_succeeded} = 1;

		$target_parameters->{has_failed} = 0;

       		my $now = $self->{datetime}->long();

		$self->{database}->update_proxy(

				$target_parameters, 

				$now, 
			);
	}
	else {
		$self->{logging}->entry( 2, "Discarding" );
	}

	$self->set_next_task();
}

1;
