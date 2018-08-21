package Lib::Info;

use Lib::Info::MLDBM;

use Data::Dumper;

sub new {

	my $class = shift;

	my $self = {};

	bless( $self, $class );

	if ( $self->{config} = shift ) {

		defined( $self->{config}->{db_file} )
			or die __PACKAGE__ . "->new() missing database file name"; 

		$self->{info} = Lib::Info::MLDBM->new(

				 $self->{config}->{db_file}

			) or die __PACKAGE__ . "->new() " . __PACKAGE__ . "::MLDBM->new() failed";
	}

	return $self;
}

sub file {

	my $self = shift;

	if ( $self->{config} = shift ) {

		defined( $self->{config}->{db_file} )
			or die __PACKAGE__ . "->new() missing database file name"; 

		$self->{info} = Lib::Info::MLDBM->new(

				 $self->{config}->{db_file}

			) or die __PACKAGE__ . "->new() " . __PACKAGE__ . "::MLDBM->new() failed";
	}
}

sub get {

	my $self = shift;

	my $key = shift
		or die __PACKAGE__ . "->get() missing argument"; 

	return $self->{info}->get( $key );
}

sub set {

	my $self = shift;

	my $key = shift
		or die __PACKAGE__ . "->set() missing argument"; 

	my $ref = shift
		or die __PACKAGE__ . "->set() missing argument"; 

	return $self->{info}->set( $key, $ref );
}

sub delete {

	my $self = shift;

	my $key = shift
		or die __PACKAGE__ . "->delete() missing argument"; 

	return $self->{info}->delete( $key );
}

sub get_pid {

	my $self = shift;

	my $data = $self->get( qw(data) );

	return $data->{pid};
}

sub set_pid {

	my $self = shift;

	my $ref = shift
		or die __PACKAGE__ . "->set_pid() missing argument"; 

	my $data = $self->get( qw(data) );

	$data->{pid} = $ref;

	$self->set( qw(data), $data );

	return $data->{pid};
}

sub delete_pid {

	my $self = shift;

	my $data = $self->get( qw(data) );

	$pid = $data->{pid};

	delete( $data->{pid} );

	$self->set( qw(data), $data );

	return $pid;
}

sub get_job {

	my $self = shift;

	my $data = $self->get( qw(data) );

	return $data->{job};
}

sub set_job {

	my $self = shift;

	my $ref = shift
		or die __PACKAGE__ . "->set_job() missing argument"; 

	my $data = $self->get( qw(data) );

	$data->{job} = $ref;

	$self->set( qw(data), $data );

	return $data->{job};
}

sub get_task {

	my $self = shift;

	my $data = $self->get( qw(data) );

	if (defined($data->{task})) {

		return split( ":", $data->{task} );
	}

	return ();
}

sub set_task {

	my $self = shift;

	my $ref = shift;
		#or die __PACKAGE__ . "->set_task() missing argument"; 

	my $data = $self->get( qw(data) );

	$data->{task} = $ref;

	$self->set( qw(data), $data );

	return split( ":", $data->{task} );
}

sub set_task_failed {

	my $self = shift;

	my $ref = shift
		or die __PACKAGE__ . "->set_task_failed() missing argument"; 

	my $data = $self->get( qw(data) );

	if ( defined( $data->{task_has_failed}->{$ref} ) ) {

		$data->{task_has_failed}->{$ref} += 1;
	}
	else {

		$data->{task_has_failed}->{$ref} = 1;
	}

	$self->set( qw(data), $data );

	return $data->{task_has_failed}->{$ref};
}

sub reset_task_failed {

	my $self = shift;

	my $ref = shift
		or die __PACKAGE__ . "->reset_task_failed() missing argument"; 

	my $data = $self->get( qw(data) );

	if ( defined( $data->{task_has_failed}->{$ref} ) ) {

		delete( $data->{task_has_failed}->{$ref} );
	}

	$self->set( qw(data), $data );

	return $data->{task_has_failed};
}

sub get_proxies {

	my $self = shift;

	my $data = $self->get( qw(data) );

	return $data->{proxies};
}

sub set_proxies {

	my $self = shift;

	my $proxies = shift
		or die __PACKAGE__ . "->set_proxies() missing argument"; 

	my $data = $self->get( qw(data) );

	$data->{proxies} = $proxies;

	$self->set( qw(data), $data );
}

1;
