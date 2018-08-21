package Explorer::Parser::Exporo;

=pod

=head1 NAME

Explorer::Parser::Exporo - Class to parse exporo.de exploration data.

=head1 SYNOPSIS

=head1 DESCRIPTION

Parse exporo.de exploration data.

Inherits from base class Lib::Parser.

=cut

use Lib::Parser;

@ISA = ( "Lib::Parser" );

use Mojo::DOM58;

=head1 METHODS

=head2 explore 

Find active campaigns and parse campaign name and uri (request).

=cut

sub explore {

	my $self = shift;

	my $result = shift
		or die __PACKAGE__ . "->explore() missing argument";

	my $data = shift
		or die __PACKAGE__ . "->explore() missing argument";

	my $prefix = 'https://exporo.de';

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

	# featured project

	$html->find( 'div.home-project__feature' )->each( sub {

		if ( my $feature = $_->parent ) {

			my %tags = ();

			$tags{request} = $self->uri( $feature->attr( 'href' ), $prefix );

			if ( my $name = $_->at( 'h4.inner' ) ) {

				$tags{name} = $self->trim( $name->text );
			}

			if ( $self->{config} ) { 

				$tags{seed} = $self->seed();
			}

			push( @entries, \%tags );
		}
	} );

	$html->find( 'div.project__teaser' )->each( sub {

		if ( my $banner = $_->at( 'div.project-ribbon span' ) ) {

			my $banner_text = $self->trim( $banner->text );

			if ( $banner_text !~ /Coming/ && $banner_text !~ /Erfolgreich/ && $banner_text !~ /Bereits/ ) {

				if ( my $anchor = $_->at( 'a.project__teaser' ) ) {

					my %tags = ();

					$tags{request} = $self->uri( $anchor->attr('href'), $prefix );

					# img + div > div > b
					if ( my $name = $_->at( 'div > div > b' ) ) {

						$tags{name} = $self->trim( $name->text );
					}

       	 				if ( $self->{config} ) { 

						$tags{seed} = $self->seed();
					}

					push( @entries, \%tags );
				}
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
