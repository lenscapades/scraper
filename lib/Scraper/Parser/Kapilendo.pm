package Scraper::Parser::Kapilendo;

=pod

=head1 NAME

Scraper::Parser::Kapilendo - Class to parse kapilendo.de campaign data.

=head1 SYNOPSIS

	use Scraper::Parser::Kapilendo;

	my $parser = Scraper::Parser::Kapilendo->new();

	$parser->scrape( $result, $dataref );

=head1 DESCRIPTION

Parse kapilendo.de campaign data.

=cut

use Lib::Parser;

@ISA = ( "Lib::Parser" );

use Mojo::DOM58;

=head1 METHODS

=head2 scrape 

Scrape kapilendo.de campaign data.

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

	if ( my $name = $dom->at( 'div.poster-container div.title h1' ) ) {

		$tags{name} = $self->trim( $name->text );
	}

	my $active_campaign = 0;

	$dom->find( 'div.project-facts-summary dl dt' )->each( sub {

		if ( $_->text =~ /^Verbleibende Tage/ ) {

			if ( my $days =  $_->next ) {

				if ( $self->trim( $days->text ) =~ /^(\d+)\s+/ ) {

					$tags{end_date} = $self->end_date( $1 . " Tage" );

					$active_campaign = 1;
				}
			}
		}

		if ( $_->text =~ /^Finanzierungsschwelle/ ) {

			if ( my $amount =  $_->next ) {

				$tags{threshold_amount} = $self->amount( $amount->text );
			}
		}

		if ( $_->text =~ /^Bereits\s[investiert|finanziert]/ ) {

			if ( my $amount =  $_->next ) {

				$tags{currency} = $self->currency( $amount->text );

				$tags{raised_amount} = $self->amount( $amount->text );
			}
		}

		if ( $_->text =~ /^Finanzierungslimit/ ) {

			if ( my $amount =  $_->next ) {

				$tags{goal_amount} = $self->amount( $amount->text );
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

		if ( $self->trim( $content ) =~ /kapilendo/i ) {

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
