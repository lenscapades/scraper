package Lib::Database::Proxy;

use Lib::Database;

@ISA = ( "Lib::Database" );

use Data::Dumper;

sub update_proxy {

	my $self = shift;

	my $proxy = shift
		or die __PACKAGE__ . "->update_proxy() missing argument";

	my $date = shift
		or die __PACKAGE__ . "->update_proxy() missing argument";

	my $dbh = $self->connect();

	my $sql = "SELECT id, has_succeeded, has_failed "
		. "FROM proxy "
		. "WHERE ip = " . $dbh->quote( $proxy->{ip} ) . " "
		. "AND port = " . $dbh->quote( $proxy->{port} );

	my $row = $self->select_one_row( $dbh, $sql );

	if ( @$row ) {

		$sql = "UPDATE proxy "
			. "SET checked = " . $dbh->quote( $date ) . ", "
			. "has_succeeded = " . $dbh->quote( $row->[1] + $proxy->{has_succeeded} ) . ", "
			. "has_failed = " . $dbh->quote( $row->[2] + $proxy->{has_failed} ) . " "
			. "WHERE id = " . $dbh->quote( $row->[0] );
	}
	else {
		$sql = "INSERT "
			. "INTO proxy ( "
				. "ip, port, seed, checked, has_succeeded, has_failed "
			. ") "
			. "VALUES ( "
				. $dbh->quote( $proxy->{ip} ) . ", " 
				. $dbh->quote( $proxy->{port} ) . ", " 
				. $dbh->quote( $proxy->{seed} ) . ", " 
				. $dbh->quote( $date ) . ", "
				. $dbh->quote( $proxy->{has_succeeded} ) . ", "
				. $dbh->quote( $proxy->{has_failed} ) ." "
			. ")";
	}

	$sth = $dbh->prepare( $sql );

	$sth->execute();

	$sth->finish();

	$self->disconnect( $dbh );
}

sub get_unchecked_proxy {

	my $self = shift;

	my $date = shift
		or die __PACKAGE__ . "->update_proxy() missing argument";

	my $offset = shift;

	if ( !defined( $offset ) ) {

		die __PACKAGE__ . "->update_proxy() missing argument";
	}

	my $checked = $self->{datetime}->offset( $date, $offset );

	my $dbh = $self->connect();

	my $sql = "SELECT ip, port FROM proxy WHERE checked < ? LIMIT 1";

	$sth = $dbh->prepare( $sql );

	$sth->execute( $checked );

	my @row = $sth->fetchrow_array();

	$sth->finish();

	$self->disconnect( $dbh );

	if ( defined( $row[0] ) && $row[0] ) {

		return $row[0] . ':' . $row[1];
	}

	return undef;
}


sub update_proxy_result {

	my $self = shift;

	my $proxy = shift
		or die __PACKAGE__ . "->update_proxy_result() missing argument";

	my ( $ip, $port ) = split( ':', $proxy );

	my $date = shift
		or die __PACKAGE__ . "->update_proxy_result() missing argument";

	my $result = shift;

	if ( !defined( $result ) ) {

		die __PACKAGE__ . "->update_proxy_result() missing argument";
	}

	my $has_succeeded = 0;

	my $has_failed = 0;

	if ( $result ) {

		$has_succeeded = 1;
	}
	else {
		$has_failed = 1;
	}

	my $dbh = $self->connect();

	my $sql = "SELECT id, has_succeeded, has_failed "
		. "FROM proxy "
		. "WHERE ip = " . $dbh->quote( $ip ) . " "
		. "AND port = " . $dbh->quote( $port );

	my $row = $self->select_one_row( $dbh, $sql );

	$sql = "UPDATE proxy "
		. "SET checked = " . $dbh->quote( $date ) . ", "
		. "has_succeeded = " . $dbh->quote( $row->[1] + $has_succeeded ) . ", "
		. "has_failed = " . $dbh->quote( $row->[2] + $has_failed ) . " "
		. "WHERE id = " . $dbh->quote( $row->[0] );

	my $sth = $dbh->prepare( $sql );

	$sth->execute();

	$sth->finish();

	$self->disconnect( $dbh );
}

sub get_proxies {

	my $self = shift;

	my $dbh = $self->connect();

	my $limit = 100;

	my $weight = 75.0;

	$sql = sprintf( "SELECT ip, port, has_succeeded, has_failed, "
		. "( ( (avg_vote * avg_rating) + ( (has_succeeded + has_failed) * (has_succeeded - has_failed) ) ) / (avg_vote + has_succeeded + has_failed) ) AS score, "
		. "100 * has_succeeded / (has_succeeded + has_failed ) AS weight "
		. "FROM proxy "
		. "INNER JOIN (SELECT ((SUM(has_succeeded) + SUM(has_failed)) / COUNT(id)) AS avg_vote FROM proxy) AS t1 "
		. "INNER JOIN (SELECT ((SUM(has_succeeded) - SUM(has_failed)) / COUNT(id)) AS avg_rating FROM proxy) AS t2 "
		. "WHERE 100 * has_succeeded / (has_succeeded + has_failed ) > %f "
		. "ORDER BY score DESC LIMIT %d",
		$weight, 
		$limit );

	#print "$sql\n";

	my $rows = $self->select_all_rows( $dbh, $sql );

	$self->disconnect( $dbh );

	return $rows;
}

1;
