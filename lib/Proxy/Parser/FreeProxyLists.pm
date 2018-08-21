package Proxy::Parser::FreeProxyLists;

=pod

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Proxy::Parser::Target;

@ISA = ( "Proxy::Parser::Target" );

use URI::Escape;

use HTML::Entities;

=head1 ATTRIBUTES

=head2 prefix 

=cut

sub prefix {

	my $self = shift;

	return 'http://www.freeproxylists.com';
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

	use  Mojo::DOM58;

	my $dom = Mojo::DOM58->new( $$data );

	$dom->find( 'table' )->each( sub {

		if ( my $header = $_->at( 'tr' ) ) {

			if ( $header =~ /raw proxy list/ ) {

				$_->find( 'tr > td > a' )->each( sub {

					if ( $_->text =~ /detailed list/ ) {

						if ( my $href = $_->attr( 'href' ) ) {

							if ( $href =~ /elite\/(d[^\.]+)\.html$/ ) {

								my %tags = ();

								my $uri = '/load_elite_' . $1 . '.html';

								$tags{uri} = $self->uri( $uri, $self->prefix );

								if ( $self->{config} ) {

                                					$tags{seed} = $self->seed();
								}

								push( @entries, \%tags );
							}
						}
					}
				} );

				return;
			}
		}
	} );

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

	my $dom = Mojo::DOM58->new( decode_entities( uri_unescape( $$data ) ) );

	$dom->find( 'table tr' )->each( sub {

		my @row = ();

		$_->find('td')->each( sub {

			push( @row, $_->text );
		} );

		if ( defined($row[2]) && ( $row[2] =~ /true/i ) ) {

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
