package Scraper::Parser::DeutscheMikroinvest;

=pod

=head1 NAME

Scraper::Parser::DeutscheMikroinvest - Class to parse deutsche-mikroinvest.de campaign data.

=head1 SYNOPSIS

	use Scraper::Parser::DeutscheMikroinvest;

	my $parser = Scraper::Parser::DeutscheMikroinvest->new();

	$parser->scrape( $result, $dataref );

=head1 DESCRIPTION

Parse deutsche-mikroinvest.de campaign data.

=cut

use Lib::Parser;

@ISA = ( "Lib::Parser" );

use Mojo::DOM58;

=head1 METHODS

=head2 scrape 

Scrape deutsche-mikroinvest.de campaign data.

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

		if ( $self->trim( $title->content ) =~ /service/i ) {

			$result->error( 1 );

			$result->message( "404 Page not found." );

			return;
		}
	}
	else {

		$result->error( 1 );

		$result->message( "Missing <title> data." );

		return;
	}

	my %tags = ();

	if ( my $slide = $dom->at( 'div.slide' ) ) {

		if ( my $h2 = $slide->at( 'h2' ) ) {

			$tags{name} = $self->trim( $h2->text );
		}
	}

	my $active_campaign = 0;

	$dom->find( 'ul#project_sidebar_team_details li' )->each( sub {

		if ( $_ =~ /Fundingschwelle/ ) {

			$tags{threshold_amount} = $self->amount( $_->text );
		}

		if ( $_ =~ /Zeichnungsvolumen/ ) {

			$tags{goal_amount} = $self->amount( $_->text );

			$tags{currency} = $self->currency( $_->text );
		}

		if ( $_->attr( 'class' ) && $_->attr( 'class' ) eq "days_left_for_investment" ) {

			if ( my $strong = $_->at( 'strong' ) ) {

				$tags{end_date} = $self->end_date( $strong->text );

				$active_campaign = 1;
			}
		}
	} );

	if ( defined( $tags{name} ) ) {

		if ( !$active_campaign ) {

			%tags = ();

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

		if ( $self->trim( $content ) =~ /^service/i ) {

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
