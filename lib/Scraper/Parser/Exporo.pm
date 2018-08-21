package Scraper::Parser::Exporo;

=pod

=head1 NAME

Scraper::Parser::Exporo - Class to parse exporo.de campaign data.

=head1 SYNOPSIS

	use Scraper::Parser::Exporo;

	my $parser = Scraper::Parser::Exporo->new();

	$parser->scrape( $result, $dataref );

=head1 DESCRIPTION

Parse exporo.de campaign data.

=cut

use Lib::Parser;

@ISA = ( "Lib::Parser" );

use Mojo::DOM58;

use JSON::PP;

use Encode qw(encode);

=head1 METHODS

=head2 scrape

Scrape exporo.de campaign data.

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

	my $sdata = undef;

	$dom->find( 'script' )->each( sub {

		my $script = $self->trim( shift );

		if ( $script =~ /<script>\s*dataLayer\.push\((\{\s*'project':.*)\);/ ) {

			$sdata = $1;

			$sdata =~ s/\'/\"/g;

			return;
		}
	} );

	my $phref = undef;

	eval {
		$phref = decode_json( encode( 'UTF-8', $sdata ) );
		1;

	} or do {

		$result->error( 1 );

		chomp( $@ );

		$result->message( $@ );

		$result->content( $sdata );
	};

	my $href = $phref->{project};

	my %tags = ();

	$tags{name}		= $href->{projectName};

	$tags{goal_amount}	= $self->amount( $href->{fundingGoal} );

	$tags{raised_amount}	= $self->amount( $href->{amountAlreadyInvestet} );

	if ( my $key = $dom->at( 'div.project__summary-detail span.key' ) ) {

		if ( $self->trim( $key->text ) =~ /Finanzierungsziel/ ) {

			if ( my $key_next = $key->next ) {

				$tags{currency} = $self->currency( $key_next->text );
			}
		}
	}

	if ( $href->{remainingDaysToInvest} ) {

		$tags{end_date} = $self->end_date( $href->{remainingDaysToInvest} . " Tage" );
	}

	if ( my $ribbon = $html->at( 'div.project-ribbon.blue-light.transparent' ) ) {

		if ( my $span = $ribbon->at( 'span' ) ) {

			if ( $self->trim( $span->content ) =~ /^Erfolgreich/i ) {

				$tags{funding_terminated} = 1;
			}

			if ( $self->trim( $span->content ) =~ /Laufzeit$/msi ) {

				if ( defined( $tags{funding_terminated} ) ) {

					delete( $tags{funding_terminated} );
				}
			}
		}
	}

	if ( defined( $tags{name} ) ) {

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

		if ( $self->trim( $content ) =~ /Exporo/i ) {

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
