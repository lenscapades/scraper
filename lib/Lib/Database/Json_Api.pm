package Lib::Database::Json_Api;

use Lib::Database;

@ISA = ( "Lib::Database" );

use Data::Dumper;

sub select_active_campaigns_by_day {

	my $self = shift;

	my $day = shift
		or die __PACKAGE__ . "->select_active_campaigns_by_day() missing argument";

	my $dbh = $self->connect();

	my $sql = sprintf( "CALL active_campaigns_by_day( %s, 0 )", $dbh->quote( $day ) );

	my $row = $self->select_one_row( $dbh, $sql );

	$self->disconnect( $dbh );

	return $row;
}

1;
