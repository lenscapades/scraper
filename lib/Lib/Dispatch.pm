package Lib::Dispatch;

use Lib::Datetime;

sub new {

	my $class = shift;

	my $self = {};

	bless( $self, $class );

	$self->{config} = shift
		or die __PACKAGE__ . "->new() missing config data";

	$self->{logging} = shift
		or die __PACKAGE__ . "->new() missing logging object";

	$self->{info} = shift
		or die __PACKAGE__ . "->new() missing info object";

	$self->{named_parameters} = shift;

	if ( !defined( $self->{named_parameters}->{caller} ) ) {

		die __PACKAGE__ . "->new() missing argument";
	}

	$self->{datetime} = Lib::Datetime->new( $self->{config} )
		or die __PACKAGE__ . "->new() Lib::Datetime->new() failed";

	return $self;
}

sub caller {

	my $self = shift;

	if ( defined( $self->{named_parameters}->{caller} ) && !$self->{caller} ) {

		$self->{caller} = lc( $self->{named_parameters}->{caller} );
	}

	return $self->{caller};
}

sub schedule {

	my $self = shift;

	my $date = shift
                or die __PACKAGE__ . "->date() missing argument";

	my $timestamp = $self->{datetime}->epoch_local( $date );

	$self->{info}->set_job( $timestamp );

	print "Scheduled next run at $date\n";

	$self->{info}->set_task( "sleep" );
}

sub sleeping {

	my $self = shift;

	my $duration = shift
                or die __PACKAGE__ . "->sleeping() missing argument";

	if ( $duration > 1 ) {

		$self->{logging}->entry( 2, "Sleeping for $duration seconds ... " );
	}
	else {
		$self->{logging}->entry( 2, "Sleeping for $duration second ... " );
	}

	sleep( $duration );

	$self->{logging}->entry( 2, "Wakeing" );
}

sub set_job {

	my $self = shift;

	my $now = shift
		or die __PACKAGE__ . "->set_job() missing argument";

	my $ref = shift
		or die __PACKAGE__ . "->set_job() missing argument";

	if( $now > $ref ) {

		my $n = ( $now - $ref ) / $self->{config}->{job_interval};

		my $job = $ref + $self->{config}->{job_interval} * int( $n + 1 );

		$self->report( $job );

		$self->{info}->set_job( $job );

		return;
	}

	my $job = $ref + $self->{config}->{job_interval};

	$self->report( $job );

	$self->{info}->set_job( $job );
}

sub get_job {

	my $self = shift;

	my $job = $self->{info}->get_job();

	$self->{info}->set_task( "sleep:$job" );
}

sub set_task {

	my $self = shift;

	if ( $self->caller eq qw(proxy) ) {

		$self->{info}->set_task( "proxy" );
	}

	if ( $self->caller eq qw(explorer) ) {

		$self->{info}->set_task( "explore" );
	}

	if ( $self->caller eq qw(scraper) ) {

		$self->{info}->set_task( "scrape" );
	}
}

sub run {

	my $self = shift;

	my @task = $self->{info}->get_task();

	if ( !@task ) {

		my $now = time();

		my $job = $now + $self->{config}->{job_interval};

		$self->report( $job );

		$self->{info}->set_job( $job );

		$self->set_task();

		return;
	}
 
	if ( defined($task[0]) && $task[0] eq "sleep" ) {

		if ( defined($task[1]) ) {

			my $now = time();

			if ( $now > $task[1] ) {

				$self->set_job( $now, $task[1] );

				$self->set_task();
			}
			else {
				$self->sleeping( $self->{config}->{wake_interval} );
			}		
		}
		else {
			$self->get_job();
		}
	}
}

sub report {

	my $self = shift;

	my $timestamp = shift
		or die __PACKAGE__ . "->report() missing argument";

	my $date = $self->{datetime}->long( $timestamp );

	$self->{logging}->entry( 1, "Scheduled next run at $date" );
}

1;
