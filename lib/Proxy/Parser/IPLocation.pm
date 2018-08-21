package Proxy::Parser::IPLocation;

use Proxy::Parser::Target;

@ISA = ( "Proxy::Parser::Target" );

=pod

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

=head1 METHODS

=head2 explore

=cut

sub check {

	my $self = shift;

	my $result = shift
		or die __PACKAGE__ . "->explore() missing argument";

	my $data = shift
		or die __PACKAGE__ . "->explore() missing argument";

	my @entries = ();

	use  Mojo::DOM58;

	my $dom = Mojo::DOM58->new( $$data );

	$dom->find( 'table[class="iptable"] td > span' )->each( sub {

		if( my $text = $self->trim( $_->content ) ) {

			if ( $text =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/ ) {

				my %tags = ();

				$tags{ip} = $1;

				push( @entries, \%tags );
			}
		}
	} );

	$result->content( \@entries );
}

1;
