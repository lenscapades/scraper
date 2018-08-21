package Proxy::Scrape;

use List::Util qw(shuffle);

use Data::Dumper;

use Lib::Get;

use Lib::Proxy;

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

	$self->{proxy} = Lib::Proxy->new(

				$self->{config},

				$self->{info}

		) or die __PACKAGE__ . "->new() Lib::Proxy->new() failed";

	return $self;
}

sub use_proxy {

	my $self = shift;

	if ( my $proxy = shift ) {

		$self->{use_proxy} = $proxy;
	}

	return $self->{use_proxy};
}

sub use_filter {

	my $self = shift;

	if ( my $filter = shift ) {

		$self->{use_filter} = $filter;
	}

	return $self->{use_filter};
}

sub run {

	my $self = shift;

	my $task_uri = undef;

	if ( my @task = $self->task( \$task_uri ) ) {

		if ( defined( $task[2] ) ) {

			$self->{logging}->entry( 1,  "Scraping $task_uri ..." );

			$self->get( $task[2] );
		}
	}
}

sub task {

	my $self = shift;

	my $task_uri = shift
		or die __PACKAGE__ . "->task() missing argument";

	my @task = $self->{info}->get_task();

	if ( !defined( $task[2] ) ) {

		my $targets = $self->get_targets();

		$self->{info}->set_targets( qw(check), [] );

		if( @$targets ) {

			$task[2] = 0;

			$self->{info}->set_task( join( ":", @task ) );
		}
		else {

			$self->{info}->set_task( qw(sleep) );

			return undef;
		}
	}

	my $parameters = $self->get_target_parameters( $task[2] );

	$$task_uri = $parameters->{request};

	return @task;
}

sub get_targets {

	my $self = shift;

	my $entries = $self->{info}->get_targets( qw(scrape) );

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

	$self->{info}->reset_task_failed( join( ':', @task ) );

	my $target = $self->get_next_target( $task[2] );

	if ( defined( $target ) ) {

		$task[2] = $target;

		$self->{info}->set_task( join( ":", @task ) );
	}
	else {

		$self->{info}->set_task( qw(proxy:check) );
	}
}

sub get_next_target {

	my $self = shift;

	my $target = shift;

	if ( !defined( $target ) ) {

		die __PACKAGE__ . "->get_next_target() missing argument";
	}

	if ( defined( $target ) ) {

		my $entries = $self->{info}->get_targets( qw(scrape) );

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

	my $entries = $self->{info}->get_targets( qw(scrape) );

	my $i = int $target;

	return $entries->[$i];
}

sub report {

	my $self = shift;

	my $results = shift
		or die __PACKAGE__ . "->report() missing argument";

	my $cnt = scalar @$results;

	if ( $cnt > 1 ) {

		$self->{logging}->entry( 2, "Found " . $cnt . " targets" );
	}
	elsif ( $cnt < 1 )  {

		$self->{logging}->entry( 2, "No targets found" );
	}
	else {

		$self->{logging}->entry( 2, "Found " . $cnt . " target" );
	}

	return $cnt;
}

sub get_results {

	my $self = shift;

	my $results = shift
		or die __PACKAGE__ . "->get_results() missing argument";

	if ( $self->report( $results ) ) {

		my $entries = $self->{info}->get_targets( qw(check) );

		foreach my $item ( @$results ) {

			push( @$entries, $item );
		}

		$self->{info}->set_targets( qw(check), $entries );
	}
}

sub get {

	my $self = shift;

	my $target = shift;

	if ( !defined( $target ) ) {

		die __PACKAGE__ . "->get() missing argument";
	}

	my $target_parameters = $self->get_target_parameters( $target );

	if ( $self->use_proxy ) {

		$target_parameters->{proxy} = $self->{proxy}->get_proxy();
	}

	if ( $self->use_filter ) {

		$target_parameters->{filter} = $self->use_filter;
	}

	my $get = Lib::Get->new(

			$self->{config},

			$self->{logging}, {

				proxy => defined( $target_parameters->{proxy} ),

				agent => 1,

				daemon => qw(Proxy)

			}

		) or die __PACKAGE__ . "->get() Lib::Get->new() failed";

	my $response = $get->get_response( $target_parameters );

	if ( !$response->is_error ) {

		my $response_content = $response->content();

		if ( defined( $response_content ) && $response_content ) {

			my $result = $get->get_content( $response_content );

			if ( $result->is_error ) {

				$self->{proxy}->update_proxy( $target_parameters->{proxy}, 0 );

				$self->set_retry();
			}
			else {

				my $result_content = $result->content();

				if ( @$result_content ) {

					$self->{proxy}->update_proxy( $target_parameters->{proxy}, 1 );

					$self->get_results( $result_content );

					$self->set_next_task();
				}
				else  {

					$self->{proxy}->update_proxy( $target_parameters->{proxy}, 0 );

					$self->{logging}->entry( 1, "No entries" );

					$self->set_retry_task();
				}
			}
		}
		else {

			$self->{proxy}->update_proxy( $target_parameters->{proxy}, 0 );

			$self->{logging}->entry( 1, "Unknown error" );

			$self->set_retry_task();
		}
	}
	else {

		$self->{proxy}->update_proxy( $target_parameters->{proxy}, 0 );

		my $response_message = $response->message;

		if ( $response_message =~ /^403/ || $response_message =~ /^5/ ) {

				$self->set_retry_task();
		}
		else {

			$self->set_skip_task();
		}
	}
}

1;
