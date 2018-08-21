package Lib::Database;

use DBI;

use Data::Dumper;

use Lib::Datetime;

sub new {

	my $class = shift;

	my($self) = {};

	bless( $self, $class );

	$self->{config} = shift
		or die __PACKAGE__ . "->new() missing config data";

	$self->{datetime} = Lib::Datetime->new(
				$self->{config}
			)
		or die __PACKAGE__ . "->new() Lib::Datetime->new() failed";

	return $self;
}

sub connect {

	my $self = shift;

	my $db_name = $self->{config}->{db_name};

	my $db_host = $self->{config}->{db_host};

	my $db_user = $self->{config}->{db_user};

	my $db_pass = $self->{config}->{db_pass};

	$dbh = DBI->connect( 
		"DBI:mysql:database=" . $db_name . ";host=" . $db_host,
		$db_user,
		$db_pass,
		{ 'PrintError' => 0, 'RaiseError' => 1 }
	);

	$dbh->{ 'mysql_enable_utf8mb4' } = 1;

	$dbh->do( "SET NAMES 'utf8mb4'" );

#	$dbh->do( "SET GLOBAL sql_mode=(SELECT REPLACE(\@\@sql_mode,'ONLY_FULL_GROUP_BY',''))" );

	return $dbh;
}

sub disconnect {

	my $self = shift;

	my $dbh = shift
		or die __PACKAGE__ . "->disconnect() missing argument";

	$dbh->disconnect();
}

sub select_one_row {

	my $self = shift;

	my $dbh = shift
		or die __PACKAGE__ . "->select_one_row() missing argument";

	my $sql = shift
		or die __PACKAGE__ . "->select_one_row() missing argument";

	my $sth = $dbh->prepare( $sql );

	$sth->execute();

	my @row = $sth->fetchrow_array();

	$sth->finish();

	return \@row;
}

sub select_all_rows {

	my $self = shift;

	my $dbh = shift
		or die __PACKAGE__ . "->select_all_rows() missing argument";

	my $sql = shift
		or die __PACKAGE__ . "->select_all_rows() missing argument";

	my $sth = $dbh->prepare( $sql );

	$sth->execute();

	my @stash = ();

	my $hash_ref = undef;

	while ( $hash_ref = $sth->fetchrow_hashref ) {

		push( @stash, $hash_ref );	
	}

	$sth->finish();

	return \@stash;
}

=head2 seed 

=cut

sub seed {

	my $self = shift;

        if ( $self->{config} ) { 

		my $seed_diff =  $self->{config}->{seed_max} - $self->{config}->{seed_min};

		return $self->{config}->{seed_min} + int rand $seed_diff;
	}

	return 0;
}

1;
