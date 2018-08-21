package Lib::Info::Storable;

use Storable qw( nstore_fd retrieve_fd );
use Fcntl qw( :DEFAULT :flock );

sub new {

	my $class = shift;

	my $self = {};

	bless($self, $class);

	$self->{db_file}= shift
		or die __PACKAGE__ . "->new() missing database file name"; 

	return $self;
}

sub load_hash {

	my $self = shift;

	my $fh = undef;

	if ( -s $self->{db_file} ) {

		sysopen( $fh, $self->{db_file}, O_RDWR|O_CREAT, 0666 )
			or die __PACKAGE__ . "->load_hash() failed accessing hash file";

		flock( $fh, LOCK_SH );

		$self->{db_hash} = retrieve_fd( $fh )
			or die __PACKAGE__ . "->load_hash() failed reading hash file";

		close($fh);

	}
	else {
		$self->{db_hash} = {};
	}

	return $self->{db_hash};
}

sub save_hash {

	my $self = shift;

	my $fh = undef;

	sysopen( $fh, $self->{db_file}, O_RDWR|O_CREAT, 0666 )
		or die __PACKAGE__ . "->save_hash() failed accessing hash file";

	flock( $fh, LOCK_EX );

	nstore_fd( $self->{db_hash}, $fh )
		or die __PACKAGE__ . "->save_hash() failed to write hash file";

	truncate( $fh, tell($fh) );

	close($fh);

	return $self->{db_hash};
}

sub get {

	my $self = shift;

	$self->load_hash();

	if (@_) { 
		my $key = shift; 

		if ( defined( $self->{db_hash}->{$key} ) ) {

			$var = $self->{db_hash}->{$key};

		}
		else {
			$var = undef;
		}
	}
	else {
		$var = $self->{db_hash};
	}

	return $var;
}

sub set {

	my $self = shift;

	my $key = shift
		or die __PACKAGE__ . "->set() missing argument"; 

	my $var = shift
		or die __PACKAGE__ . "->set() missing argument"; 

	$self->load_hash();

	$self->{db_hash}->{$key} = $var;

	$self->save_hash();

	return $var;
}

sub delete {

	my $self = shift;

	my $key = shift
		or die __PACKAGE__ . "->delete() missing argument"; 

	$self->load_hash();

	if ( defined( $self->{db_hash}->{$key} ) ) {

		$var = $self->{db_hash}->{$key};

		delete($self->{db_hash}->{$key});
	}
	else {
		$var = undef;
	}

	$self->save_hash();

	return $var;
}

1;
