package Explorer::Parser::Kickstarter;

=pod

=head1 NAME

Explorer::Parser::Kickstarter - Class to parse kickstarter.com exploration data.

=head1 SYNOPSIS

=head1 DESCRIPTION

Parse kickstarter.com exploration data.

Inherits from base class Lib::Parser.

=cut

use Lib::Parser;

@ISA = ( "Lib::Parser" );

use Mojo::DOM58;

use URI::Escape;

use HTML::Entities;

use Encode qw(encode decode);

use JSON::PP;

use Data::Dumper;

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

	my $prefix = 'https://www.kickstarter.com';

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
		$self->locale( 'en-US' );
	}

	my @json_data = ();

	$html->find( 'div[data-project]' )->each( sub {

		if ( $_->attr( 'data-ref' ) eq 'category_newest' ) {
	
			push( @json_data, decode_entities( uri_unescape( $_->attr( 'data-project' ) ) ) );
		}
	} );

	undef $html;

	foreach my $jdata ( @json_data ) {

		$jdata = encode_entities( $jdata, '\x{10}-\x{16}' );

		$href = decode_json( encode( 'UTF-8', $jdata ) );

		if ( defined( $href->{state} ) && $href->{state} eq qw(live) ) {

			my %tags = ();

			$tags{request} = $href->{urls}->{web}->{project} . '?ref=category_newest';

			$tags{name} = $href->{name};

			$tags{start_date} = $self->date( $href->{launched_at} );

			$tags{end_date} = $self->date( $href->{deadline} );

			if ( $self->{config} ) { 

				$tags{seed} = $self->seed();
			}

			push( @entries, \%tags );
		}
	}

	$result->content( \@entries );

	$result->extra( { per_page => 12 } );
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
