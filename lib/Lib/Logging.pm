package Lib::Logging;

use Lib::Datetime;

use FileHandle;
use File::Copy;

sub new {

	my $class = shift;

	my $self = {};

	bless( $self, $class );

	$self->{config} = shift
		or die __PACKAGE__ . "->new() missing config data";

	defined( $self->{config}->{log_file} )
		or die __PACKAGE__ . "->new() missing log file name in config data";

	my $named_parameters = shift;

	$self->verbose( $named_parameters->{verbose} );

	$self->{log_file_handle} = undef;

	$self->{datetime} = new Lib::Datetime( $self->{config} )
		or die __PACKAGE__ . "->new() Datetime->new() failed"; 

	$self->file( $self->{config}->{log_file} );

	$self->level( $self->{config}->{log_level} );

	return $self;
}

sub verbose {

	my $self = shift;

	if ( my $verbose = shift ) {

		$self->{verbose} = $verbose;
	}

	return $self->{verbose};
}

sub caller {

	my $self = shift;

	if ( my $caller = shift ) {

		$self->{caller} = $caller;
	}

	return $self->{caller};
}

sub file {

	my $self = shift;

	$self->{log_file} = shift
		or die __PACKAGE__ . "->_file() missing argument"; 

	$self->archive();

	sysopen( 
		$self->{log_file_handle},
		$self->{log_file}, 
		O_CREAT|O_APPEND|O_RDWR, 
		0666 
	)
	or die __PACKAGE__ . "->_file() failed accessing log file";

	$self->{log_file_handle}->autoflush(1);

	return $self->{log_file_handle};
}

sub archive {

	my $self = shift;

	if ( -e $self->{log_file} ) {

		my $mtime = ($self->{datetime}->range( $self->{datetime}->long( (stat( $self->{log_file} ))[9] ) ))->[1];

		my $etime = ($self->{datetime}->range( $self->{datetime}->long() ))->[0];

		if ( $self->{datetime}->compare( $mtime, $etime ) < 0 ) {

			$self->move_log_file( $mtime );

			return;
		}

		open( FH, "<", $self->{log_file} );

		my $line = <FH>;

		close( FH );

		my $ltime = undef;

		if ( $line && $line =~ /^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\s/ ) {

			$ltime = ($self->{datetime}->range( $1 ))->[1];
		}

		if ( $ltime && $self->{datetime}->compare( $ltime, $etime ) < 0 ) {

			$self->move_log_file( $ltime );

			return;
		}
	}
}

sub move_log_file {

	my $self = shift;

	my $datetime = shift
		or die __PACKAGE__ . "->_move() missing argument";

	my $path = undef;

	my $file = undef;

	if ( $self->{log_file} =~ /^(.+\/)([^\/]+)$/ ) {

		$path = $1;

		$file = $2;
	}
	else {

		die __PACKAGE__ . "->_move() could not parse log file name";
	}

	if ( $datetime =~ /^(\S+)/ ) {

		$date = $1;
	}
	else {

		die __PACKAGE__ . "->_move() could not parse datetime";
	}

	my $archive_file = $path . $date . "-" . $file;

	if ( ! -e $archive_file ) {

		File::Copy::move( $self->{log_file}, $archive_file );
	}
}

sub level {

	my $self = shift;

	my $log_level = shift;

	if ( defined( $log_level ) ) {

		$self->{log_level} = $log_level;
	}

	return $self->{log_level};
}

sub entry {

	my $self = shift;

	my $level = shift
		or die . __PACKAGE__ . "->entry() missing argument";

	my $log_text = shift
		or die . __PACKAGE__ . "->entry() missing argument";

	if ( $level <= $self->{log_level} ) {

		print {$self->{log_file_handle}} $self->{datetime}->long() . " " . $self->caller . ": $log_text\n";

		if ( $self->verbose ) { print $self->caller . ": $log_text\n"; }
	}
}

1;
