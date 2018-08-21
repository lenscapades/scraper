package Scraper::Parser::Companisto;

=pod

=head1 NAME

Explorer::Parser::Companisto - Class to parse companisto.com campaign data.

=head1 SYNOPSIS

	use Scraper::Parser::Companisto;

	my $parser = Scraper::Parser::Companisto->new();

	$parser->scrape( $result, $dataref );

=head1 DESCRIPTION

Parse companisto.com campaign data.

=cut

use Lib::Parser;

@ISA = ( "Lib::Parser" );

use Mojo::DOM58;

use Encode qw(encode);

=head1 METHODS

=head2 scrape 

Scrape companisto.com campaign data.

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

	if ( my $title = $html->at( 'title' ) ) {

		if ( encode( 'UTF-8', $self->trim( $title->content ) ) =~ /Investmentmöglichkeiten/i ) {

			$result->error( 1 );

			$result->message( "404 Page not found." );

			return;
		}
	}

	my %tags = ();

	if ( my $name = $dom->at( 'div.headerGreen h1' ) ) {

		if ( $name->text =~ /(\S+)/ ) {

			$tags{name} = $1;
		}
	}
	else
	{
		if ( my $name = $dom->at( 'div.main-title h1' ) ) {

			if ( $name->text =~ /(\S+)/ ) {

				$tags{name} = $1;
			}
		}
	}

	my $active_campaign = 0;

	$dom->find( 'div.sidebarBox div.body p' )->each( sub {

		if ( $_->text =~ /Companisten/ ) {

			if ( my $span = $_->previous ) {

				$tags{funders} = $self->trim( $span->text );
			}
		}

		if ( $_->text =~ /Investiert/ ) {

			if ( my $span = $_->previous ) {

				$tags{raised_amount} = $self->amount( $span->text );

				$tags{currency} = $self->currency( $span->text );
			}
		}

		if ( $_->at( 'span' ) && $self->trim( $_->at( 'span' )->text ) =~ /Fundingzeit/ ) {

			if ( my $span = $_->previous ) {

				if ( $span =~ /(\d+)\s+(Tage|Stunden)/ ) {
	
					$tags{end_date} = $self->end_date( $span->text );

					$active_campaign = 1;
				}
			}
		}

		if ( $_->at( 'span' ) && $self->trim( $_->at( 'span' )->text ) =~ /(Tage|Stunden)\s+Fundingzeit/ ) {

			if ( my $span = $_->previous ) {

				$tags{end_date} = $self->end_date( $span->text . " $1" );

				$active_campaign = 1;
			}
		}

		if ( $_->at( 'span' ) && $_->at( 'span' )->text =~ /Investmentschwelle/ ) {

			if ( my $span = $_->previous ) {

				$tags{threshold_amount} = $self->amount( $span->text );
			}
		}

		if ( $_->at( 'span' ) && $_->at( 'span' )->text =~ /Finanzierungsziel/ ) {

			if ( my $span = $_->previous ) {

				$tags{goal_amount} = $self->amount( $span->text );
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

		if ( $self->trim( $content ) =~ /^Crowdfunding/i ) {

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
