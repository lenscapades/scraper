package Scraper::Parser::Seedmatch;

=pod

=head1 NAME

Scraper::Parser::Seedmatch - Class to parse seedmatch.de campaign data.

=head1 SYNOPSIS

	use Scraper::Parser::Seedmatch;

	my $parser = Scraper::Parser::Seedmatch->new();

	$parser->scrape( $result, $dataref );

=head1 DESCRIPTION

Parse seedmatch.de campaign data.

=cut

use Lib::Parser;

@ISA = ( "Lib::Parser" );

use Mojo::DOM58;

=head1 METHODS

=head2 scrape 

Scrape seedmatch.de campaign data.

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

	if ( my $name = $dom->at( 'h1#fundingTitle a' ) ) {

		$tags{name} = $self->trim( $name->text );
	}

	my $active_campaign = 0;

	$dom->find( 'div.highlight' )->each( sub {

		my $popup = undef;

		if ( my $p = $_->next ) {

			if ( my $clapdown = $p->next ) {

				$popup = $clapdown->at( 'span.popup' );
			}

			if ( $p->text =~ /^von/ ) {

				$tags{currency} = $self->currency( $p->text );

				$tags{raised_amount} = $self->amount( $_->text );

				$tags{goal_amount} = $self->amount( $p->text );
			}

			if ( $p->text =~ /Euro investiert/ ) {

				$tags{currency} = $self->currency( $p->text );

				$tags{raised_amount} = $self->amount( $_->text );
			}

			if ( $p->text =~ /Euro Fundingziel/ ) {

				$tags{goal_amount} = $self->amount( $_->text );

				if ( $popup ) {

					if ( $popup =~ /(.*)Fundingschwelle(.*)/ ) {

						$tags{limit_amount} = $self->amount( $1 );

						$tags{threshold_amount} = $self->amount( $2 );
					}
				}
			}

			if ( $p->text =~ /Euro Fundingschwelle/ ) {

				$tags{threshold_amount} = $self->amount( $_->text );

				if ( $popup ) {

					$tags{limit_amount} = $self->amount( $popup );
				}
			}

			if ( $p->text =~ /Euro Fundinglimit/ ) {

				$tags{limit_amount} = $self->amount( $_->text );

				if ( $popup ) {

					$tags{threshold_amount} = $self->amount( $popup );
				}
			}

			if ( $p->text =~ /Investoren/ ) {

				$tags{funders} = $self->trim( $_->text );
			}

			if ( $p->text =~ /(Tage|Stunden)\s+noch/ ) {

				$tags{end_date} = $self->end_date( $_->text . " $1" );

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

		if ( $content =~ /Seedmatch/i ) {

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
