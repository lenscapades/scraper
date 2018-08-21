package Lib::Parser;

=pod

=head1 NAME

Lib::Parser - Base class

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Lib::Datetime;

use Encode qw(encode);

use Encode::Guess;

use Data::Dumper;

sub new {

	my $class = shift;

	my $self = {};

	bless( $self, $class );

	$self->{config}	= shift;

	$self->{logging} = shift;

	$self->{named_parameters} = shift; 

	$self->{datetime} = Lib::Datetime->new(
				$self->{config}
			)
		or die __PACKAGE__ . "->new() Lib::Datetime->new() failed";

	return $self;
}

=head1 ATTRIBUTES

=head2 type

=cut

sub type {

        my $self = shift;

        if ( $self->{named_parameters}->{type} ) {

		$self->{type} = $self->{named_parameters}->{type};

	}

        return $self->{type};
}

=head2 request

=cut

sub request {

        my $self = shift;

        if ( $self->{named_parameters}->{request} ) {

		$self->{request} = $self->{named_parameters}->{request};

	}

        return $self->{request};
}

=head2 time_zone

=cut

sub time_zone {

        my $self = shift;

        if ( $self->{named_parameters}->{time_zone} ) {

		$self->{time_zone} = $self->{named_parameters}->{time_zone};
	}

        return $self->{time_zone};
}

=head2 locale

=cut

sub locale {

        my $self = shift;

	my $locale = shift;

        if ( $locale ) {

		$self->{locale} = $locale;
	}

        return $self->{locale};
}

=head1 METHODS

=head2 trim 

=cut

sub trim {

	my $self = shift;

	my @out = @_ ? @_ : $_;

	$_ = join( ' ', split( ' ' ) ) for @out;

	return wantarray ? @out : "@out";
}

=head2 uri 

=cut

sub uri {

	my $self = shift;

	my $uri = shift
		or die __PACKAGE__ . "->uri() missing argument";

	my $prefix = shift
		or die __PACKAGE__ . "->uri() missing argument";

	if ( $uri =~ /^$prefix/ ) {

		return $uri;
	}
	else {
		return $prefix . $uri;
	}
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

sub amount {

	my $self = shift;

	my $value = shift;

	$value = $self->trim( $value );

	my $amount = undef;

	my $locale = $self->locale;

	if ( $locale eq 'en' || $locale eq 'en-US' ) {

		if ( $value =~ /((\d+\,{0,1})+(\.\d+){0,1})/ ) {

			$amount = $1;

			$amount =~ s/\,//g;
		}

		return $amount;
	}

	if ( $value =~ /((\d+\.{0,1})+(\,\d+){0,1})/ ) {

		$amount = $1;

		$amount =~ s/\.//g;

		$amount =~ s/\,/\./g;
	}

	return $amount;
}

sub currency {

	my $self = shift;

	my $value = shift;

	$value = $self->trim( $value );

	if ( $value =~ /euro/i ) {

		return 'EUR';
	}

	my $euro = '€';

	if ( $value =~ /$euro/ || $value =~ /\x{20AC}/ ) {

		return 'EUR';
	}

	my $dollar = '$';

	if ( $value =~ /$dollar/ || $value =~ /\x{0024}/ ) {

		return 'USD';
	}

	return undef;
}

sub end_date {

	my $self = shift;

	my $time_left = shift;

	if ( !defined( $time_left ) ) {

		die __PACKAGE__ . "->end_date() missing argument";
	}

	$time_left = $self->trim( $time_left );

	if ( ( $time_left =~ /^noch\s+(\d+)\s+Tage$/ ) ||
		( $time_left =~ /^noch\s+(\d+)\s+Tag$/ ) ||
		( $time_left =~ /^(\d+)\s+Tage$/ ) ||
		( $time_left =~ /^(\d+)\s+Tag$/ ) ||
		( $time_left =~ /^(\d+)\s+days\s+left$/ ) ||
		( $time_left =~ /^(\d+)\s+day\s+left$/ ) ) {

		return ($self->{datetime}->range( $self->{datetime}->project( $1 * 24 * 60 * 60, $self->time_zone )))->[1];
	}

	if ( ( $time_left =~ /^noch\s+(\d+)\s+Stunden$/ ) ||
		( $time_left =~ /^noch\s+(\d+)\s+Stunde$/ ) ||
		( $time_left =~ /^noch\s+(\d+)\s+Std(\.){0,1}$/ ) ||
		( $time_left =~ /^(\d+)\s+Stunden$/ ) ||
		( $time_left =~ /^(\d+)\s+Stunde$/ ) ||
		( $time_left =~ /^(\d+)\s+Std(\.){0,1}$/ ) ||
		( $time_left =~ /^(\d+)\s+hours\s+left$/ ) ||
		( $time_left =~ /^(\d+)\s+hour\s+left$/ ) ) {

		return ($self->{datetime}->range_hours( $self->{datetime}->project( $1 * 60 * 60, $self->time_zone )))->[1];
	}

	if ( ( $time_left =~ /^noch\s+(\d+)\s+Minuten$/ ) ||
		( $time_left =~ /^noch\s+(\d+)\s+Minute$/ ) ||
		( $time_left =~ /^noch\s+(\d+)\s+Min(\.){0,1}$/ ) ||
		( $time_left =~ /^(\d+)\s+Minuten$/ ) ||
		( $time_left =~ /^(\d+)\s+Minute$/ ) ||
		( $time_left =~ /^(\d+)\s+Min(\.){0,1}$/ ) ||
		( $time_left =~ /^(\d+)\s+minutes\s+left$/ ) ||
		( $time_left =~ /^(\d+)\s+minute\s+left$/ ) ) {

		return ($self->{datetime}->range_minutes( $self->{datetime}->project( $1 * 60, $self->time_zone )))->[1];
	}

	if ( ( $time_left =~ /^noch\s+(\d+)\s+Sekunden$/ ) ||
		( $time_left =~ /^noch\s+(\d+)\s+Sekunde$/ ) ||
		( $time_left =~ /^noch\s+(\d+)\s+Sek(\.){0,1}$/ ) ||
		( $time_left =~ /^(\d+)\s+Sekunden$/ ) ||
		( $time_left =~ /^(\d+)\s+Sekunde$/ ) ||
		( $time_left =~ /^(\d+)\s+Sek(\.){0,1}$/ ) ||
		( $time_left =~ /^(\d+)\s+seconds\s+left$/ ) ||
		( $time_left =~ /^(\d+)\s+second\s+left$/ ) ) {

		return $self->{datetime}->project( $1, $self->time_zone );
	}

	return undef;
}

sub date {

	my $self = shift;

	my $date = shift
		or die __PACKAGE__ . "->date() missing argument";

	$date = $self->trim( $date );

	return $self->{datetime}->parse(
			$date, {
				time_zone => $self->time_zone
			}
		);
}

1;
