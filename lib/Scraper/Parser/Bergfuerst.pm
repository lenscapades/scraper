package Scraper::Parser::Bergfuerst;

=pod

=head1 NAME

Scraper::Parser::Bergfuerst - Class to parse bergfuerst.com campaign data.

=head1 SYNOPSIS

	use Scraper::Parser::Bergfuerst;

	my $parser = Scraper::Parser::Bergfuerst->new();

	$parser->scrape( $result, $dataref );

=head1 DESCRIPTION

Parse bergfuerst.com campaign data.

=cut

use Lib::Parser;

@ISA = ( "Lib::Parser" );

use Mojo::DOM58;

use Encode qw(encode);

use Data::Dumper;

=head1 METHODS

=head2 scrape 

Scrape bergfuerst.com campaign data.

=cut

sub scrape {

	my $self = shift;

	my $result = shift
		or die __PACKAGE__ . "->scrape() missing argument";

	my $data = shift
		or die __PACKAGE__ . "->scrape() missing argument";

	my $dom = Mojo::DOM58->new( $data );

	my $html = $dom->at( 'html' );

	if ( !$html ) {

		$result->error( 1 );

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

	my %tags = ();

	if ( my $h1 = $dom->at( 'h1.target-profile-heading' ) ) {

		$tags{name} = $self->trim( $h1->text );
	}
		
	if ( my $p = $dom->at( 'p.target-profile-header-price' ) ) {

		if ( my $span = $p->at( 'span.js-countup' ) ) {

			$tags{currency} = $self->currency( $p->text );

			$tags{raised_amount} = $self->amount( $span->attr( 'data-targetvalue' ) );
		}
		else {

			my $content = $self->trim( $p->content );

			if ( $content !~ /\%/ ) {

				$tags{currency} = $self->currency( $content );

				$tags{raised_amount} = $self->amount( $content );
			}
		}
	}

	$dom->find( 'div.target-profile-header-infos div.row div' )->each( sub {

		if ( my $p = $_->at( 'p.target-profile-header-caption' ) ) {

			my $p_text = $self->trim( $p->text );

			if ( $p_text =~ /Investoren/ ) {

				if ( my $info = $_->at( 'p.target-profile-header-info' ) ) {

					$tags{funders} = $self->trim( $info->text );
				}
			}
		}
	} );

	my $active_campaign = 0;

	$dom->find( 'dl.dl-stacked.dl-details.widget dt' )->each( sub {

		my $dt_text = $self->trim( $_->text );

		if ( $dt_text =~ /Finanzierungsziel/ ) {

			if ( my $dd = $_->next ) {

				$tags{goal_amount} = $self->amount( $dd->text );
			}
		}

		if ( $dt_text =~ /Kategorie/ ) {

			if ( my $dd = $_->next ) {

				$tags{category} = $self->trim( $dd->text );
			}
		}

		if ( $dt_text =~ /Fundingende/ ) {

			if ( my $dd = $_->next ) {

				$tags{end_date} = $self->end_date( $dd->text );

				$active_campaign = 1;
			}
		}
	} );

	if ( defined( $tags{name} ) ) {

		if ( !$active_campaign ) {

			$tags{funding_terminated} = 1;
		}

       		if ( $self->{config} ) { 

			$tags{seed} = $self->seed();
		}

		$result->message( 'All OK.' );

		$result->content( \%tags );
	}
	else {

		$result->error(1);

		$result->message( 'No data.' );
	}
}

sub not_found {

	my $self = shift;

	my $result = shift
		or die __PACKAGE__ . "->scrape() missing argument";

	my $data = shift
		or die __PACKAGE__ . "->scrape() missing argument";

	my $dom = Mojo::DOM58->new( $data );

	my $html = $dom->at( 'html' );

	if ( !$html ) {

		$result->error( 1 );

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

	if ( my $content = $html->at( 'title' )->content ) {

		if ( $self->trim( $content ) =~ /^Fehler 404/i ) {

			$result->message( "Genuine 404 error." );

			$result->content( $content );

			return;
		}
	}

	$result->error( 1 );

	$result->message( "Non-genuine 404 error." );
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
