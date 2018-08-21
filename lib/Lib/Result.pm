package Lib::Result;

sub new {

	my $class = shift;

	my $self = {};

	bless($self, $class);

	$self->{error} = 0;

	$self->{message} = undef;

	$self->{content} = undef;

	$self->{extra} = undef;

	return $self;
}

sub error {

	my $self = shift;

	if (@_) { $self->{error} = shift; }

	return $self->{error};
}

sub is_error {

	my $self = shift;

	return $self->{error};
}

sub message {

	my $self = shift;

	if (@_) { $self->{message} = shift; }

	return $self->{message};
}

sub content {

	my $self = shift;

	if (@_) { $self->{content} = shift; }

	return $self->{content};
}

sub extra {

	my $self = shift;

	if (@_) { $self->{extra} = shift; }

	return $self->{extra};
}

1;
