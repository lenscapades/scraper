package Proxy::Parser::BNLGov;

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

	if ( my $item = $dom->find( 'strong' )->first( qr/Your IP Address is/i ) ) {

		my $ip = $self->trim( $item->next_node->next_node );

		if ( $ip =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/ ) {

			my %tags = ();

			$tags{ip} = $1;

			push( @entries, \%tags );
		}
	} 

	$result->content( \@entries );
}

1;
