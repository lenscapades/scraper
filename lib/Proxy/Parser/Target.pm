package Proxy::Parser::Target;

=pod

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

=head1 CONSTRUCTOR

=cut

sub new {

	my $class = shift;

	my $self = {};

	bless( $self, $class );

	$self->{verbose}		= undef;

	$self->{config}			= shift;

	$self->{named_parameters}	= shift; 

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

=head2 locale

=cut

sub locale {

        my $self = shift;

        if ( $self->{named_parameters}->{locale} ) {

		$self->{locale} = $self->{named_parameters}->{locale};
	}

        return $self->{locale};
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

=head2 uri 

=cut

sub uri {

	my $self = shift;

	my $uri = shift or die __PACKAGE__ . "->uri() missing argument";

	my $prefix = shift or die __PACKAGE__ . "->uri() missing argument";

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

=head2 trim 

=cut

sub trim {

	my $self = shift;

	my @out = @_ ? @_ : $_;

	$_ = join( ' ', split( ' ' ) ) for @out;

	return wantarray ? @out : "@out";
}

=head2 use_filter 

=cut

sub use_filter {

	my $self = shift;

	if ( my $filter = shift ) {

		$self->{filter} = $filter;
	}

	return $self->{filter};
}

1;
