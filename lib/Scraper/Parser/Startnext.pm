package Scraper::Parser::Startnext;

=pod

=head1 NAME

Scraper::Parser::Startnext - Class to parse startnext.com campaign data.

=head1 SYNOPSIS

	use Scraper::Parser::Startnext;

	my $parser = Scraper::Parser::Startnext->new();

	$parser->scrape( $result, $dataref );

=head1 DESCRIPTION

Parse startnext.com campaign data.

Inherits from base class Lib::Parser.

=cut

use Lib::Parser;

@ISA = ( "Lib::Parser" );

use Mojo::DOM58;

use Encode qw(encode);

=head1 METHODS

=head2 scrape 

Scrape startnext.com campaign data.

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

		if ( encode( 'UTF-8', $self->trim( $title->content ) ) =~ /Startnext - Crowdfunding([\-\s]Plattform){0,1} für (Ideen, ){0,1}Projekte und Startups/i ) {

			$result->error( 1 );

			$result->message( "404 Page not found." );

			return;
		}

		if ( encode( 'UTF-8', $self->trim( $title->content ) ) =~ /Startnext - Crowdfunding und Finanzierung für Gründer, Erfinder und Kreative/i ) {

			$result->error( 1 );

			$result->message( "404 Page not found." );

			return;
		}
	}

	my %tags = ();

	if ( my $h1 = $dom->at( 'header[role="banner"] h1' ) ) {

		$tags{name} = $self->trim( $h1->text );
	}

	if ( my $breadcrumb = $dom->at( 'section.vcard div.vcard__breadcrumb' ) ) {

		$category = $breadcrumb->text;

		$category =~ s/\///;

		$tags{category} = $self->trim( $category );
	}

	if ( my $description = $dom->at( 'div.fact.fact-funding div div.description' ) ) {

		if ( $self->trim( $description->text ) =~ /(.+)\sFunding(ziel|schwelle)/ ) {

			my $amount = $1;

			$tags{currency} = $self->currency( $amount );

			$tags{goal_amount} = $self->amount( $amount );

			if ( my $value = $description->previous ) {

				$tags{raised_amount} = $self->amount( $value->text );
			}
		}
	}

	$dom->find( 'div.fact.fact-supporter div' )->each( sub {

		if ( my $description = $_->at( 'div.description' ) ) {

			if ( encode( 'UTF-8', $self->trim( $description->text ) ) =~ /Unterstützer/ ) {

				if ( my $value = $_->at( 'div.value' ) ) {

					$tags{funders} = $self->trim( $value->text );
				}
			}
		}
	} );

	if ( my $funding_period = $dom->at( 'div.fact.article-funding-period' ) ) {

		if ( my $caption = $funding_period->at( 'span.caption' ) ) {

			if ( $self->trim( $caption->text ) =~ /Finanzierungszeitraum/ ) {

				if ( my $start_value = $funding_period->at( 'span.value' ) ) {

					if ( my $start_date = $start_value->at( 'span.date' ) ) {

						$tags{start_date} = $start_date->text;

						if ( my $start_time = $start_date->at( 'span.time' ) ) {

							$tags{start_date} .= " " . $start_time->text;
						}

						$tags{start_date} = $self->date( $tags{start_date} );
					}	
				}

				if ( my $upto = $funding_period->at( 'span.upto' ) ) {

					if ( my $end_date = $upto->next ) {

						$tags{end_date} = $end_date->text;

						if ( my $end_time = $end_date->at( 'span.time' ) ) {

							$tags{end_date} .= " " . $end_time->text;
						}

						$tags{end_date} = $self->date( $tags{end_date} );	
					}	
				}
				else
				{
					$tags{end_date} = $tags{start_date};

					$tags{start_date} = undef;
				}
			}
		}
	}

	$dom->find( 'div.fact.article-funding-target' )->each( sub {

		my $funding_target = $_;

		if ( my $caption = $funding_target->at( 'span.caption' ) ) {

			if ( my $amount = $funding_target->at( 'span.value' ) ) {

				$tags{goal_amount} = $self->amount( $amount->text );
			}
		}
	} );

	$dom->find( 'div.fact.article-funding-threshold' )->each( sub {

		my $funding_threshold = $_;

		if ( my $caption = $funding_threshold->at( 'span.caption' ) ) {

			if ( my $amount = $funding_threshold->at( 'span.value' ) ) {

				my $value = $self->amount( $amount->text );

				if ( $value != $tags{goal_amount} ) {

					$tags{threshold_amount} = $value;
				}
			}
		}
	} );

	if ( $self->{datetime}->compare( $tags{end_date}, $self->{datetime}->long() ) < 0 ) {

		$tags{funding_terminated} = 1;
	}

       	if ( $self->{config} ) { 

		$tags{seed} = $self->seed();
	}

	$result->message( 'All OK.' );

	$result->content( \%tags );
}

=head2 not_found

verify igenuineess of 404 page.nity.

=cut

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

		if ( $content =~ /startnext/i ) {

			$result->message( "Genuine 404 error." );

			$result->content( $content );

			return ;
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
