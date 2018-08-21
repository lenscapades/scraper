package Explorer::Parser::Seedmatch;

=pod

=head1 NAME

Explorer::Parser::Seedmatch - Class to parse seedmatch.de exploration data.

=head1 SYNOPSIS

=head1 DESCRIPTION

Parse seedmatch.de exploration data.

Inherits from base class Lib::Parser.

=cut

use Lib::Parser;

@ISA = ( "Lib::Parser" );

use Mojo::DOM58;

=head1 METHODS

=head2 explore 

Find active campaigns and parse campaign name, uri (request) and end date.

=cut

sub explore {

	my $self = shift;

	my $result = shift
		or die __PACKAGE__ . "->explore() missing argument";

	my $data = shift
		or die __PACKAGE__ . "->explore() missing argument";

	my $prefix = 'https://www.seedmatch.de';

	$self->locale( 'de-De' );

	my @entries = ();

	my $dom = Mojo::DOM58->new( $data );

	my $html = $dom->at( 'html' );

	if ( !$html ) {

		$result->error(1);

		$result->message( "Missing HTML data." );

		$result->content( $data );

		return;
	}

	if ( my $lang = $html->attr( 'lang' ) ) {

		$self->locale( $lang );
	}
	else {
		$self->locale( 'de-DE' );
	}

	$html->find( 'div.investment-window' )->each( sub {

		if ( my $time = $_->at( 'span.time' ) ) {

			if ( my $end_date = $self->end_date( $time->text ) ) {

				my %tags = ();

				$tags{request} = $self->uri( $_->at( 'a' )->attr( 'href' ), $prefix );

				if ( my $header = $_->at( 'h3' ) ) {

					$tags{name} = $self->trim( $header->text );
				}

				$tags{end_date} = $end_date;

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

__END__

=head1 COPYRIGHT

Copyright (c) 2017 by Marcus Hogh. All rights reserved.

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see L<http://www.gnu.org/licenses/>.

=head1 AUTHOR

S<Marcus Hogh E<lt>hogh@lenscapades.comE<gt>>

=head1 HISTORY

2017-04-20 Initial Version

=cut
