package Proxy::Parser::Astrill;

use Proxy::Parser::Target;

@ISA = ( "Proxy::Parser::Target" );

=pod

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

=head1 METHODS

=head2 check

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

	if ( my $headline = $dom->at( 'table h1' ) ) {

		if ( my $ip = $headline->text ) {

			my %tags = ();

			$tags{ip} = $self->trim( $ip );

			push( @entries, \%tags );
		}
	} 

	$result->content( \@entries );
}

1;
