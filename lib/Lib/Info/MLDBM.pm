package Lib::Info::MLDBM;

use MLDBM qw(DB_File);
use Fcntl;

use Data::Dumper;

sub new {

	my $class = shift;

	my $self = {};

	bless( $self, $class );

	if ( my $db_file = shift ) {

		$self->file( $db_file );
	}

	return $self;
}

sub file {

	my $self = shift;

	if ( my $db_file = shift ) {

		$self->{db_file} = $db_file;
	}

	return $self->{db_file};
}

sub get {

	my $self = shift;

	$self->{db_hash} = {};

	tie(
		%{$self->{db_hash}},
		"MLDBM",
		$self->{db_file}, 
		O_RDWR|O_CREAT, 
		0666
	)
	or die __PACKAGE__ . "->get() failed to access hash file";

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

	untie( %{$self->{db_hash}} );

	return $var;
}

sub set {

	my $self = shift;

	my $key = shift
		or die __PACKAGE__ . "->set() missing argument"; 

	my $var = shift
		or die __PACKAGE__ . "->set() missing argument"; 

	$self->{db_hash} = {};

	tie(
		%{$self->{db_hash}},
		"MLDBM",
		$self->{db_file}, 
		O_RDWR|O_CREAT, 
		0666
	)
	or die __PACKAGE__ . "->set() failed to access hash file";

	$self->{db_hash}->{$key} = $var;

	untie( %{$self->{db_hash}} );

	return $var;
}

sub delete {

	my $self = shift;

	my $key = shift
		or die __PACKAGE__ . "->delete() missing argument"; 

	$self->{db_hash} = {};

	tie(
		%{$self->{db_hash}},
		"MLDBM",
		$self->{db_file}, 
		O_RDWR|O_CREAT, 
		0666
	)
	or die __PACKAGE__ . "->delete() failed to access hash file";

	if ( defined( $self->{db_hash}->{$key} ) ) {

		$var = $self->{db_hash}->{$key};

		delete($self->{db_hash}->{$key});
	}
	else {
		$var = undef;
	}

	untie( %{$self->{db_hash}} );

	return $var;
}

1;
