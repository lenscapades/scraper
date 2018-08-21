package Proxy::Parser::SSLProxies;

use Proxy::Parser::Target;

@ISA = ( "Proxy::Parser::Target" );

use Data::Dumper;

=pod

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

=head1 ATTRIBUTES

=head2 prefix 

=cut

sub prefix {

	my $self = shift;

	return 'https://www.sslproxies.org/';
}

=head1 METHODS

=head2 explore

=cut

sub explore {

	my $self = shift;

	my $result = shift
		or die __PACKAGE__ . "->explore() missing argument";

	my $data = shift
		or die __PACKAGE__ . "->explore() missing argument";

	my @entries = ();

	my %tags = ();

	$tags{uri} = $self->prefix;

	if ( $self->{config} ) {

       		$tags{seed} = $self->seed();
	}

	push( @entries, \%tags );

	$result->content( \@entries );
}

=head2 scrape

=cut

sub scrape {

	my $self = shift;

	my $result = shift
		or die __PACKAGE__ . "->scrape() missing argument";

	my $data = shift
		or die __PACKAGE__ . "->scrape() missing argument";

	my $filter = $self->use_filter;

	my @entries = ();

	use  Mojo::DOM58;

	my $dom = Mojo::DOM58->new( $$data );

	$dom->find( 'table#proxylisttable tr' )->each( sub {

		my @row = ();

		$_->find('td')->each( sub {

			push( @row, $_->text );
		} );

		if ( defined($row[4]) && ( $row[4] =~ /elite/i ) ) {

			my $keep = 0;

			if ( $filter ) {

				if ( $row[1] =~ /^$filter/ ) {

					$keep = 1;
				}
			}
			else {

				$keep = 1;
			}

			if ( $keep ) {

				my %tags = ();

				$tags{ip} = $row[0];

				$tags{port} = $row[1];

				if ( $self->{config} ) {

       		   			$tags{seed} = $self->seed();
				}

				push( @entries, \%tags );
			}
		}
	} );

	$result->content( \@entries );
}

1;
