package Proxy::Explore;

use Lib::Get;

use Lib::Proxy;

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

sub run {

	my $self = shift;

	if ( my @task = $self->task() ) {

		if ( defined( $task[2] ) ) {

			$self->{logging}->entry( 1,  "Exploring $task[2] ..." );

			$self->get( $task[2] );
		}
	}
}

sub task {

	my $self = shift;

	my @task = $self->{info}->get_task();

	if ( !defined( $task[2] ) ) {

		$self->{info}->set_targets( qw(explore), [] );

		my $targets = $self->get_targets();

		$task[2] = $targets->[0]->{target};

		$self->{info}->set_task( join( ":", @task ) );

		$self->{info}->set_targets( qw(scrape), [] );
	}

	return @task;
}

sub get_targets {

	my $self = shift;

	my $entries = $self->{info}->get_targets( qw(explore) );

	if ( !defined( $entries ) || !scalar( @$entries ) ) {

		if ( my $proxy_targets = $self->{info}->get_proxy_targets() ) {

			foreach my $target ( @$proxy_targets ) {

				push( @$entries, $self->factory_target( $target ) );
			}

			$self->{info}->set_targets( qw(explore), $entries );
		}
		else {
			die __PACKAGE__ . "->get_targets() missing proxy service targets configuration data";
		}
	}

	return $entries;
}

sub factory_target {

	my $self = shift;

	my $target = shift
		or die __PACKAGE__ . "->factory_target() missing argument";

	my %entry = ();

	if ( $target->{uri} =~ /^http[^\.]+\.([^\.]+)\./ ) {

		$entry{target}	= $1;

		$entry{type}	= qw(explore);

		$entry{start}	= $target->{start};

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

	if ( my $target = $self->get_next_target( $task[2] ) ) {

		$task[2] = $target;

		$self->{info}->set_task( join( ":", @task ) );
	}
	else {
		$self->factory_results();

		$self->{info}->set_task( qw(proxy:scrape) );
	}
}

sub factory_results {

	my $self = shift;

	my $entries = $self->{info}->get_targets( qw(scrape) );

	$self->{info}->set_targets( qw(scrape), $entries );
}

sub get_next_target {

	my $self = shift;

	my $target = shift
		or die __PACKAGE__ . "->get_next_target() missing argument";

	my $entries = $self->{info}->get_targets( qw(explore) );

	my $i = undef;

	for ( $i=0; $i < @$entries; $i++ ) {

		last if ( $entries->[$i]->{target} eq $target );
	}

	if ( $i+1 < @$entries ) {

		return $entries->[$i+1]->{target};
	}

	return undef;
}

sub get_target_parameters {

	my $self = shift;

	my $target = shift
		or die __PACKAGE__ . "->get_target_parameters() missing argument";

	my $entries = $self->{info}->get_targets( qw(explore) );

	foreach my $entry ( @$entries ) {

		return $entry if ( $entry->{target} eq $target );
	}

	return undef;
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

	my $target = shift
		or die __PACKAGE__ . "->get_results() missing argument";

	if ( $self->report( $results ) ) {

		my $entries = $self->{info}->get_targets( qw(scrape) );

		foreach my $item ( @$results ) {

			push( @$entries, $self->factory_result( $item, $target ) );
		}

		$self->{info}->set_targets( qw(scrape), $entries );
	}
}

sub factory_result {

	my $self = shift;

	my $result = shift
		or die __PACKAGE__ . "->factory_result() missing argument";

	my $target = shift
		or die __PACKAGE__ . "->factory_result() missing argument";

	my %entry = ();

	$entry{target}			= $target->{target};

	$entry{type}			= qw(scrape);

	$entry{request}			= $result->{uri};

	if ( $target->{request} eq $result->{uri} ) {

		$entry{referer}		= 'https://www.google.de';
	}
	else {
		$entry{referer}		= $target->{request};
	}

	return \%entry;
}

sub get {

	my $self = shift;

	my $target = shift
		or die __PACKAGE__ . "->get() missing argument";

	my $target_parameters = $self->get_target_parameters( $target );

	if (  $target_parameters->{start} eq qw(scrape) ) {

		my $result_content = [];

		$result_content->[0] = { uri =>  $target_parameters->{request} };

		$self->get_results( $result_content, $target_parameters );

		$self->set_next_task();

		return;
	}

	if ( $self->use_proxy ) {

		$target_parameters->{proxy} = $self->{proxy}->get_proxy();
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

					$self->get_results( $result_content, $target_parameters );

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

		$self->{logging}->entry( 1, $response_message );

		if ( $response_message =~ /^403/ || $response_message =~ /^5/ ) {

				$self->set_retry_task();
		}
		else {
			$self->set_skip_task();
		}
	}
}

1;
