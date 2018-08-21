package Lib::Database::Scraper;

use Lib::Database;

@ISA = ( "Lib::Database" );

use Data::Dumper;

sub select_all_targets_daily {

	my $self = shift;

	my $today = $self->{datetime}->range( $self->{datetime}->long() );

	my $dbh = $self->connect();

	my $sql = sprintf( "SELECT "
			. "c.id, "
			. "c.name, "
			. "c.request, "
			. "c.first_seen, "
			. "c.seed, "
			. "p.name AS target, "
			. "p.referer, "
			. "p.time_zone " 
		. "FROM "
			. "campaign c, "
			. "platform p, "
			. "( "
				. "SELECT s.campaign_id, t.end_date "
				. "FROM timeline t "
				. "INNER JOIN ( "
					. "SELECT MAX(inquiry_date) AS max_inquiry_date, campaign_id "
					. "FROM timeline "
					. "WHERE campaign_id IN ( SELECT c.id FROM campaign c, platform p WHERE c.platform_id = p.id AND p.daily = 1 ) GROUP BY campaign_id "
				. ") AS s "
				. "ON t.inquiry_date = s.max_inquiry_date "
				. "AND t.page_not_found IS NULL "
				. "AND t.funding_terminated IS NULL "
				. "AND t.inquiry_date < %s "
			. ") AS q "
			. "WHERE q.campaign_id = c.id AND c.platform_id = p.id", 
		$dbh->quote( $today->[0] ) );

	#print "$sql\n";

	my $array_ref = $self->select_all_rows( $dbh, $sql );

	$self->disconnect( $dbh );

	return $array_ref;
}

sub select_all_targets_new {

	my $self = shift;

	my $today = $self->{datetime}->range( $self->{datetime}->long( time() - 3 * 24 * 60 * 60 ) );

	my $dbh = $self->connect();

	my $sql = sprintf( "SELECT "
			. "c.id, "
			. "c.name, "
			. "c.request, "
			. "c.first_seen, "
			. "c.seed, "
			. "p.name AS target, "
			. "p.referer, "
			. "p.time_zone " 
		. "FROM "
			. "campaign c, "
			. "platform p, "
			. "( "
			. "SELECT MAX(inquiry_date) AS max_inquiry_date, campaign_id "
			. "FROM timeline "
			. "GROUP BY campaign_id "
			. ") AS m "
		. "WHERE m.campaign_id = c.id "
		. "AND m.max_inquiry_date = c.first_seen "
		. "AND c.platform_id = p.id "
		. "AND p.daily = 0 "
		. "AND c.first_seen > %s "
		. "ORDER BY c.seed",
		$dbh->quote( $today->[0] ) );

	#print "$sql\n";

	my $array_ref = $self->select_all_rows( $dbh, $sql );

	$self->disconnect( $dbh );

	return $array_ref;
}

sub select_all_targets_ending {

	my $self = shift;

	my $now = $self->{datetime}->long();

	my $today = $self->{datetime}->range( $now );

	my $begin_scraping = $self->{datetime}->range( $self->{datetime}->long( time() - $self->{config}->{begin_scraping} ) );

	my $dbh = $self->connect();

	my $sql = sprintf( "SELECT "
			. "c.id, "
			. "c.name, "
			. "c.request, "
			. "c.first_seen, "
			. "c.seed, "
			. "p.name AS target, "
			. "p.referer, "
			. "p.time_zone " 
		. "FROM "
			. "campaign c, "
			. "platform p, "
			. "( "
				. "SELECT s.campaign_id, t.end_date "
				. "FROM timeline t "
				. "INNER JOIN ( "
					. "SELECT MAX(inquiry_date) AS max_inquiry_date, campaign_id "
					. "FROM timeline "
					. "WHERE campaign_id IN ( SELECT c.id FROM campaign c, platform p WHERE c.platform_id = p.id AND p.daily = 0 ) GROUP BY campaign_id "
				. ") AS s "
				. "ON t.inquiry_date = s.max_inquiry_date "
				. "AND t.page_not_found IS NULL "
				. "AND t.funding_terminated IS NULL "
				. "AND t.inquiry_date < %s "
				. "AND t.end_date >= %s "
				. "AND t.end_date <= %s "
			. ") AS q "
			. "WHERE q.campaign_id = c.id AND c.platform_id = p.id", 
		$dbh->quote( $today->[0] ),
		$dbh->quote( $begin_scraping->[0] ),
		$dbh->quote( $now ) );

	#print "$sql\n";

	my $array_ref = $self->select_all_rows( $dbh, $sql );

	$self->disconnect( $dbh );

	return $array_ref;
}

sub select_all_targets_query {

	my $self = shift;

	my $dbh = $self->connect();

	my $sql = '';

	print "$sql\n";

	my $array_ref = $self->select_all_rows( $dbh, $sql );

	$self->disconnect( $dbh );

	return $array_ref;
}

sub update_result {

	my $self = shift;

	my $target = shift
		or die __PACKAGE__ . "->update_result() missing argument";

	my $result = shift
		or die __PACKAGE__ . "->update_result() missing argument";

	if ( !$target->{id} ) {

		die __PACKAGE__ . "->update_result() target id missing or null";
	}

	my $dbh = $self->connect();

	my $today = $self->{datetime}->long();

	my $today_range = $self->{datetime}->range( $today );

	my @timeline_fields = ( 'campaign_id', 'inquiry_date' );

	my @timeline_values = ( $dbh->quote( $target->{id} ), $dbh->quote( $today ) );

	my @campaign_fields = ();

	while ( my ($key, $value) = each( %$result ) ) {

		if ( $key eq "goal_amount" ||
			$key eq "raised_amount" || 
			$key eq "threshold_amount" ||
			$key eq "limit_amount" ||
			$key eq "end_date" ||
			$key eq "funders" ||
			$key eq "category" ||
			$key eq "currency" ||
			$key eq "funding_type" ||
			$key eq "funding_terminated" ||
			$key eq "start_date" ) {

			push( @timeline_fields, $key );

			push( @timeline_values, $dbh->quote( $value ) );
		}
		elsif ( $key eq "name" ) {

			push( @campaign_fields, $key . " = " . $dbh->quote( $value ) );
		}
	}

	if ( @campaign_fields ) {

		$sql = sprintf( "UPDATE campaign "
				. "SET %s "
				. "WHERE id = %s", 
				join( ", ", @campaign_fields ), 
				$target->{id} );
	
		#print "\n$sql\n\n";

		$sth = $dbh->prepare( $sql );

		$sth->execute();

		$sth->finish();
	}

	if ( @timeline_fields ) {

		$sql = sprintf( "INSERT INTO timeline ( %s ) "
				. "VALUES ( %s )",
				join( ", ", @timeline_fields ),
				join( ", ", @timeline_values ) );

		#print "\n$sql\n\n";

		$sth = $dbh->prepare( $sql );

		$sth->execute();

		$sth->finish();
	}

	$self->disconnect( $dbh );
}

sub not_found_result {

	my $self = shift;

	my $target = shift
		or die __PACKAGE__ . "->not_found_result() missing argument";

	if ( !$target->{id} ) {

		die __PACKAGE__ . "->not_found_result() target id missing or null";
	}

	my $dbh = $self->connect();

	my $today = $self->{datetime}->long();

	my @timeline_fields = ( 'campaign_id', 'inquiry_date', 'page_not_found' );

	my @timeline_values = ( $dbh->quote( $target->{id} ), $dbh->quote( $today ), 1 );

	$sql = sprintf( "INSERT INTO timeline ( %s ) "
			. "VALUES ( %s )",
			join( ", ", @timeline_fields ),
			join( ", ", @timeline_values ) );

	#print "\n$sql\n\n";

	$sth = $dbh->prepare( $sql );

	$sth->execute();

	$sth->finish();

	$self->disconnect( $dbh );
}

sub update_failure {

	my $self = shift;

	my $target = shift
		or die __PACKAGE__ . "->update_failure() missing argument";

	if ( !$target->{id} ) {

		die __PACKAGE__ . "->update_failure() target id missing or null";
	}

	my $dbh = $self->connect();

	my @campaign_fields = ();

	push( @campaign_fields, "seed = " . $dbh->quote( $self->seed ) );

	if ( @campaign_fields ) {

		$sql = sprintf( "UPDATE campaign "
				. "SET %s "
				. "WHERE id = %s", 
				join( ", ", @campaign_fields ), 
				$target->{id} );
	
#		print "\n$sql\n\n";

		$sth = $dbh->prepare( $sql );

		$sth->execute();

		$sth->finish();
	}

	$self->disconnect( $dbh );
}

1;
