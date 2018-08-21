package Explorer::Parser::Startnext;

=pod

=head1 NAME

Explorer::Parser::Startnext - Class to parse startnext.com exploration data.

=head1 SYNOPSIS

=head1 DESCRIPTION

Parse startnext.com exploration data.

Inherits from base class Lib::Parser.

=cut

use Lib::Parser;

@ISA = ( "Lib::Parser" );

use JSON::PP;

use Mojo::DOM58;

=head1 METHODS

=head2 explore 

Find active campaigns and parse campaign name, uri (request) and end_date.

=cut

sub explore {

	my $self = shift;

	my $result = shift
		or die __PACKAGE__ . "->explore() missing argument";

	my $data = shift
		or die __PACKAGE__ . "->explore() missing argument";

	if ( $data !~ /^\{.*\}$/ms ) {

		$result->error(1);

		$result->message( "Malformed JSON string." );

		$result->content( $data );

		return;
	}

	my $prefix = 'https://www.startnext.com';

	$self->locale( 'de-DE' );

	my @entries = ();

	my $href = decode_json( $data );

	my $dom = Mojo::DOM58->new( $href->{projectListHTML} );

	$dom->find( 'div.appArticleCell' )->each( sub {

		my %tags = ();

		if ( my $header = $_->at( 'header.headline > a' ) ) {

			$tags{request} = $self->uri( $header->attr( 'href' ), $prefix );

			$tags{name} = $self->trim( $header->text );
		}

		if ( my $footer = $_->at( 'footer.article-footer' ) ) {

			if ( my $remain = $footer->at( 'span.fact.remain span.desc' ) ) {

				if ( my $value = $remain->previous ) {

						$tags{end_date} = $self->end_date( $value->content . " " . $remain->content );
				}
			}
		}

       		if ( $self->{config} ) { 

			$tags{seed} = $self->seed();
		}

		push( @entries, \%tags );
	} );

	$result->content( \@entries );

	if ( my $per_page = $self->per_page ) {

		$result->extra( { per_page => $per_page } );
	}
}

sub per_page {

	my $self = shift;

	if ( my $request = $self->request ) {

		if ( $request =~ /\&count=(\d+)/ ) {

			return $1;
		}
	}

	return undef;
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
