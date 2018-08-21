package Lib::Datetime;

use Time::localtime;

use DateTime;

use DateTime::Format::Strptime;

sub new {

	my $class = shift;

	my $self = {};

	bless( $self, $class );

	$self->{config} = shift
		or die __PACKAGE__ . "->new() missing config data";

	defined( $self->{config}->{time_zone}{local} ) && defined( $self->{config}->{time_zone}{standard} )
		or die __PACKAGE__ . "->new() missing time_zone config data";

	return $self;
}

sub long {

	my $self = shift;

	my $timestamp = undef;

	if ( @_ ) { $timestamp = shift; }

	if ( !defined( $timestamp ) ) {

		$timestamp = time();
	}

	my $tm = localtime( $timestamp );

	my $dt = DateTime->new(
		year		=> $tm->year+1900,
		month		=> $tm->mon+1,
		day		=> $tm->mday,
		hour		=> $tm->hour,
		minute		=> $tm->min,
		second		=> $tm->sec,
		time_zone	=> $self->{config}->{time_zone}{local},
	);

	$dt->set_time_zone( $self->{config}->{time_zone}{standard} );

	return  $dt->ymd . " " . $dt->hms;
}

sub range {

	my $self = shift;

	my $datetime = shift
		or die __PACKAGE__ . "->range() missing argument";

	my @range = ();

	if ( $datetime =~ /^(\S+)/ ) {

		my $date = $1;

		@range = (
			$date . " 00:00:00", 
			$date . " 23:59:59", 
		);
	}

	return \@range;
}

sub range_hours {

	my $self = shift;

	my $datetime = shift
		or die __PACKAGE__ . "->range_hours() missing argument";

	my @range = ();

	if ( $datetime =~ /^(\S+)\s(\d{2})\:/ ) {

		my $date = $1;

		my $hours = $2;

		@range = (
			"$date $hours:00:00", 
			"$date $hours:59:59", 
		);
	}

	return \@range;
}

sub range_minutes {

	my $self = shift;

	my $datetime = shift
		or die __PACKAGE__ . "->range_minutes() missing argument";

	my @range = ();

	if ( $datetime =~ /^(\S+)\s(\d{2})\:(\d{2})\:/ ) {

		my $date = $1;

		my $hours = $2;

		my $minutes = $3;

		@range = (
			"$date $hours:$minutes:00", 
			"$date $hours:$minutes:59", 
		);
	}

	return \@range;
}


sub short {

	my $self = shift;

	my $timestamp = undef;

	if ( @_ ) { $timestamp = shift; }

	my $datetime = $self->long( $timestamp );

	$datetime =~ /(\S+)/;

	return $1;
}

sub epoch {

	my $self = shift;

	my $datetime = shift
		or die __PACKAGE__ . "->epoch() missing argument";

	my $strp = DateTime::Format::Strptime->new(
		pattern   	=> '%F %T',
		time_zone	=> $self->{config}->{time_zone}{standard},
	);

	my $dt = $strp->parse_datetime( $datetime );

	$dt->set_time_zone( $self->{config}->{time_zone}{standard} );

	return $dt->epoch();
}

=head2 epoch_local

used in Lib::Dispatch

=cut

sub epoch_local {

	my $self = shift;

	my $datetime = shift
		or die __PACKAGE__ . "->epoch_local() missing argument";

	my $strp = DateTime::Format::Strptime->new(
		pattern   	=> '%F %T',
		time_zone	=> $self->{config}->{time_zone}{standard},
	);

	my $dt = $strp->parse_datetime( $datetime );

	$dt->set_time_zone( $self->{config}->{time_zone}{local} );

	return $dt->epoch();
}

sub compare {

	my $self = shift;

	my $date1 = shift
		or die __PACKAGE__ . "->compare() missing argument";

	my $date2 = shift
		or die __PACKAGE__ . "->compare() missing argument";

	my $epoch1 = $self->epoch( $date1 );

	my $epoch2 = $self->epoch( $date2 );

	if ( $epoch1 < $epoch2 ) {

		return -1;
	}

	if ( $epoch1 > $epoch2 ) {

		return 1;
	}

	return 0;
}

sub offset {

	my $self = shift;

	my $datetime = shift
		or die __PACKAGE__ . "->offset() missing argument";

	my $offset = shift
		or die __PACKAGE__ . "->offset() missing argument";

	my $epoch = $self->epoch( $datetime );

	return $self->long( $epoch + $offset );
}

sub project {

	my $self = shift;

	my $offset = shift;

	if ( !defined( $offset ) ) {

		die __PACKAGE__ . "->project() missing argument";
	}

	my $time_zone = shift;

	if ( !defined( $time_zone ) ) {

		$time_zone = $self->{config}->{time_zone}{local};
	}

	my $tm = localtime( time() + $offset );

	my $dt = DateTime->new(
		year		=> $tm->year+1900,
		month		=> $tm->mon+1,
		day		=> $tm->mday,
		hour		=> $tm->hour,
		minute		=> $tm->min,
		second		=> $tm->sec,
		time_zone	=> $self->{config}->{time_zone}{local},
	);

	$dt->set_time_zone( $time_zone );

	my $datetime = $dt->ymd . " " . $dt->hms;

	my $strp = DateTime::Format::Strptime->new(
		pattern   	=> '%F %T',
		time_zone	=> $time_zone,
	);

	$dt = $strp->parse_datetime( $datetime );

	$dt->set_time_zone( $self->{config}->{time_zone}{standard} );

	return  $dt->ymd . " " . $dt->hms;
}

sub parse {

	my $self = shift;

	my $date = shift
		or die __PACKAGE__ . "->parse() missing argument";

	my $named_parameters = shift;

	if ( !defined( $named_parameters->{time_zone} ) ) {

		$named_parameters->{time_zone} = $self->{config}->{time_zone}{standard};
	}

	my $found = 0;

	my $strp = undef;

	my $dt = undef;

	if ( $date =~ /\d{10}/ ) {

		$found = 1;

		$strp = DateTime::Format::Strptime->new(
			pattern		=> "%s",
			time_zone	=> $named_parameters->{time_zone},
		);

		$dt = $strp->parse_datetime( $date );
	}
	elsif ( $date =~ /(-\d{2}:\d{2})$/ ) {

		my $time_zone = $1;

		my $time_zone_iso = $time_zone;

		$time_zone_iso =~ s/://,

		$date =~ s/$time_zone/$time_zone_iso/;

		$found = 1;

		$strp = DateTime::Format::Strptime->new(
			pattern		=> "%FT%T%z",
			time_zone	=> $self->{config}->{time_zone}{local},
		);

		$dt = $strp->parse_datetime( $date );
	}
	else {
		my @patterns = (
			'%F %T',
			'%F',
			'%d.%m.%y %T',
			'%d.%m.%y %R',
			'%d.%m.%y',
			'%m/%d/%Y %T',
			'%m/%d/%Y',
		);

		foreach my $pattern ( @patterns ) {

			$strp = DateTime::Format::Strptime->new(
				pattern		=> $pattern,
				time_zone	=> $named_parameters->{time_zone},
			);

			$dt = $strp->parse_datetime( $date );

			if ( !defined( $strp->errmsg ) || !$strp->errmsg ) {

				$found = 1;
				last;
			}
		}
	}

	if ( $found ) {

		$dt->set_time_zone( $self->{config}->{time_zone}{standard} );

		return  $dt->ymd . " " . $dt->hms;
	}
	else {
		die __PACKAGE__ . "->parse() could not parse date argument";
	}
}

1;
