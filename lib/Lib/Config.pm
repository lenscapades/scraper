package Lib::Config;

sub new {

	my $class = shift;

	my $self = {};

	bless( $self, $class );

	$self->{caller} = lc shift
		or die __PACKAGE__ . "->new() missing argument";

	$self->{config} = {};

	$self->{config_file} = "$ENV{HOME}/scraper/config.pl";

	return $self;
}

sub get {

	my $self = shift;

	eval { do "$self->{config_file}" }
		or die __PACKAGE__ ."->get() failed to read config file";

	$self->hash_walker( $self->{config}, \%Conf );

	return $self->{config};
}

sub hash_walker {

	my $self = shift;

	my $dest_ref = shift;

	my $src_ref = shift;

	foreach $key ( keys %$src_ref ) {

		if ( ref $src_ref->{$key} eq "HASH" ) {

			if ( defined( $src_ref->{$key}->{$self->{caller}} ) ) {

				$dest_ref->{$key} = $src_ref->{$key}->{$self->{caller}};
			}
			else {

				$dest_ref->{$key} = {};
	
				$self->hash_walker( $dest_ref->{$key}, $src_ref->{$key} );
			}
		}
		else {
			$dest_ref->{$key} = $src_ref->{$key};
		}
	}
}

1;
