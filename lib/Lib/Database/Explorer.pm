package Lib::Database::Explorer;

use Lib::Database;

@ISA = ( "Lib::Database" );

use Data::Dumper;

sub select_all_targets {

	my $self = shift;

	my $sql = "SELECT id, name, request, referer, time_zone "
		. "FROM platform "
		. "ORDER BY RAND()";

	my $dbh = $self->connect();

	my $arrayref = $self->select_all_rows( $dbh, $sql );

	$self->disconnect( $dbh );

	return $arrayref;
}

sub update_database {

	my $self = shift;

	my $target = shift
		or die __PACKAGE__ . "->update_database() missing argument";

	if ( !$target->{id} ) {

		die __PACKAGE__ . "->update_database() target id missing or null";
	}

	my $data = shift
		or die __PACKAGE__ . "->update_database() missing argument";

	my $new_campaign = 0;

	my $dbh = $self->connect();

	my $sql = "SELECT c.id, p.daily "
		. "FROM campaign c, platform p "
		. "WHERE c.request = ? AND c.platform_id = p.id";

	my $sth = $dbh->prepare( $sql );

	foreach my $item ( @$data ) {

		$sth->execute( $item->{request} );

		my @row = $sth->fetchrow_array();

		if ( !defined( $row[0] ) ) {

			$self->create_campaign( $dbh, $target, $item );

			$new_campaign++;
		}
		else {

			$self->update_campaign( $dbh, $target, $item, $row[0], $row[1] );
		}
	}

	$sth->finish();

	$self->disconnect( $dbh );

	return $new_campaign;
}

sub create_campaign {

	my $self = shift;

	my $dbh = shift
		or die __PACKAGE__ . "->create_campaign() missing argument";

	my $target = shift
		or die __PACKAGE__ . "->create_campaign() missing argument";

	my $item = shift
		or die __PACKAGE__ . "->create_campaign() missing argument";

	my $referer = $target->{referer};

	if ( $target->{page_number} < 0 ) {

		$referer = $target->{request};
	}

	my $today = $self->{datetime}->long();

	my @campaign_fields = (
		'platform_id',
		'referer',
		'first_seen',
	);

	my @campaign_values = (
		$dbh->quote( $target->{id} ),
		$dbh->quote( $referer ),
		$dbh->quote( $today ),
	);

	my @timeline_fields = (
		'inquiry_date'
	);

	my @timeline_values = (
		$dbh->quote( $today )
	);

	while ( my ($key, $value) = each( %$item ) ) {

		if ( $key eq "name" || 
			$key eq "request" || 
			$key eq "seed" ) {

			push( @campaign_fields, $key );

			push( @campaign_values, $dbh->quote( $value ) );
		}
		elsif ( $key eq "end_date" || 
			$key eq "start_date" ) {

			push( @timeline_fields, $key );

			push( @timeline_values, $dbh->quote( $value ) );
		}
	}

	my $sql = sprintf( "INSERT INTO campaign ( %s ) "
			. "VALUES ( %s )", 
			join( ", ", @campaign_fields ),
			join( ", ", @campaign_values ) );

	$sth = $dbh->prepare( $sql );

	$sth->execute();

	push( @timeline_fields, 'campaign_id' );

	push( @timeline_values, $dbh->quote( $sth->{mysql_insertid} ) );

	$sql = sprintf( "INSERT INTO timeline ( %s ) "
			. "VALUES ( %s )", 
			join( ", ", @timeline_fields ),
			join( ", ", @timeline_values ) );

	$sth = $dbh->prepare( $sql );

	$sth->execute();

	$sth->finish();
}

sub update_campaign {

	my $self = shift;

	my $dbh = shift
		or die __PACKAGE__ . "->update_campaign() missing argument";

	my $target = shift
		or die __PACKAGE__ . "->update_campaign() missing argument";

	my $item = shift
		or die __PACKAGE__ . "->update_campaign() missing argument";

	my $campaign_id = shift
		or die __PACKAGE__ . "->update_campaign() missing argument";

	my $daily = shift;

	my $sql = sprintf( "SELECT inquiry_date, page_not_found, funding_terminated "
		. "FROM timeline "
		. "WHERE campaign_id = %d "
		. "ORDER BY inquiry_date DESC "
		. "LIMIT 1 ",
		$campaign_id );	

	my $timeline_ref = $self->select_all_rows( $dbh, $sql );

	if ( $daily ) {

		if ( !$timeline_ref->[0]->{page_not_found} && !$timeline_ref->[0]->{funding_terminated} ) {

			return;
		}

	} else {

		if ( !$timeline_ref->[0]->{page_not_found} ) {

			return;
		}
	}
	
	my $today = $self->{datetime}->long();

	my @timeline_fields = (
		'inquiry_date'
	);

	my @timeline_values = (
		$dbh->quote( $today )
	);

	while ( my ($key, $value) = each( %$item ) ) {

		if ( $key eq "end_date" || 
			$key eq "start_date" ) {

			push( @timeline_fields, $key );

			push( @timeline_values, $dbh->quote( $value ) );
		}
	}

	push( @timeline_fields, 'campaign_id' );

	push( @timeline_values, $campaign_id );

	$sql = sprintf( "INSERT INTO timeline ( %s ) "
			. "VALUES ( %s )", 
			join( ", ", @timeline_fields ),
			join( ", ", @timeline_values ) );

	$sth = $dbh->prepare( $sql );

	$sth->execute();

}

sub select_campaign_data {

	my $self = shift;

	my $data = shift
		or die __PACKAGE__ . "->select_campaign_data() missing argument";

	my $values = shift
		or die __PACKAGE__ . "->select_campaign_data() missing argument";

	my $dbh = $self->connect();

	my $sql = sprintf( "SELECT %s "
			. "FROM campaign "
			. "WHERE request = ? ",
			join( ", ", @$values ) );

	my $sth = $dbh->prepare( $sql );

	@results = ();

	foreach my $item ( @$data ) {

		$sth->execute( $item->{request} );

		my $row = $sth->fetchrow_hashref();

		push( @results, $row );
	}

	$sth->finish();

	$self->disconnect( $dbh );

	return \@results;
}

1;
