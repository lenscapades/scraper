package Scraper::Parser::Indiegogo;

=pod

=head1 NAME

Scraper::Parser::Indiegogo - Class to parse indiegogo.com campaign data.

=head1 SYNOPSIS

	use Scraper::Parser::Indiegogo;

	my $parser = Scraper::Parser::Indiegogo->new();

	$parser->scrape( $result, $dataref );

=head1 DESCRIPTION

Parse indiegogo.com campaign data.

=cut

use Lib::Parser;

@ISA = ( "Lib::Parser" );

use Mojo::DOM58;

use JSON::PP;

use Encode qw(encode);

use Data::Dumper;

=head1 METHODS

=head2 scrape 

Scrape indiegogo.com campaign data.

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
		$self->locale( 'en-US' );
	}

	if ( my $title = $html->at( 'title' ) ) {

		if ( $self->trim( $title->content ) =~ /From concept to market with crowdfunding/i 
			|| $self->trim( $title->content ) =~ /Indiegogo: Crowdfund Innovations & Buy Unique Products/i ) {

			$result->error( 1 );

			$result->message( "404 Page not found." );

			return;
		}
	}

	if ( my $notice = $html->at( 'div.project-notice.indiegogo' ) ) {

		if ( $self->trim( $notice->content ) =~ /review.*check/ims ) {

			$result->error( 1 );

			$result->message( "404 Page not found." );

			return;
		}
	}

	if ( my $notice = $html->at( 'div.project-notice' ) ) {

		if ( $self->trim( $notice->content ) =~ /updated.*check/ims ) {

			$result->error( 1 );

			$result->message( "404 Page not found." );

			return;
		}
	}

	if ( my $pre_launch_show = $html->at( 'pre-launch-show' ) ) {

		if ( $pre_launch_show->attr( 'confirmed' ) =~ /false/i ) {

			$result->error( 1 );

			$result->message( "404 Page not found." );

			return;
		}
	}

	undef $html;

	my $fvalue = undef;

	my $hvalue = undef;

	$dom->find( 'script' )->each( sub {

		my $script = shift;

		if ( $script =~ /window\.gon/ ) {

			$script =~ s/^<script>\s*\/\/<!\[CDATA\[\s*//;
			$script =~ s/\s*\/\/\]\]>\s*<\/script>$//;

			if ( $script =~ /gon\.data_layer/ ) {

				@sdata = split( "};", $script );

				foreach $sdata ( @sdata ) {

					if ( $sdata =~ /gon\.default_event_tags\s*=\s*(.*)/ ) {

						$fvalue = $1 . "}";
					}

					if ( $sdata =~ /gon\.campaign\s*=\s*(.*)/ ) {

						$hvalue = $1 . "}";
					}
				}
			}

			if ( $script =~ /gon\.campaign\s*=\s*(.*?(?=;gon))/ ) {

				$hvalue = $1;
			}
		}
	} );

	undef $dom;

	undef $data;

	my $fref = undef;

	if ( defined( $fvalue )  ) {

		eval {
			$fref = decode_json( $fvalue );
			1;

		} or do {

			if ( $@ =~ /^malformed/i || $@ =~ /wide/i ) {

				$fvalue = encode( 'UTF-8', $fvalue );

				$fref = undef;
			}
			else {
				$result->error( 1 );

				chomp( $@ );

				$result->message( $@ );

				return;
			}
		};

		if ( !defined($fref) ) {

			$fref = decode_json( $fvalue );
		}

		undef $fvalue;
	}

	if ( defined( $fref ) && $fref->{page} eq qw(fundraiser_page) ) {

		$result->error( 1 );

		$result->message( "Fundraiser page." );

		return
	}

	if ( !defined( $hvalue ) ) {

		$result->error( 1 );

		$result->message( "Missing JSON data." );

		return
	}

	my $href = undef;

	eval {
		$href = decode_json( $hvalue );
		1;

	} or do {

		if ( $@ =~ /^malformed/i || $@ =~ /wide/i ) {

			$hvalue = encode( 'UTF-8', $hvalue );

			$href = undef;
		}
		else {
			$result->error( 1 );

			chomp( $@ );

			$result->message( $@ );

			$result->content( $hvalue );

			return;
		}
	};

	if ( !defined($href) ) {

		$href = decode_json( $hvalue );
	}

	undef $hvalue;

	my %tags = ();

	$tags{name}		= $href->{title};

	$tags{category}		= $href->{category}->{name};

	$tags{currency}		= $href->{currency}->{iso_code};

	if ( defined( $href->{external_campaign_info}->{external_platform} ) ) {

		$tags{funding_type}	= 'forever';

		$tags{raised_amount} 	= $href->{forever_funding_combined_balance};
	}
	else {

		$tags{funding_type}	= $href->{funding_type};

		$tags{goal_amount}	= $href->{goal};

		$tags{raised_amount}	= $href->{collected_funds};
	}

	$tags{funders}		= $href->{contributions_count};

	$tags{start_date}	= $self->date( $href->{funding_started_at} );

	$tags{end_date}		= $self->date( $href->{funding_ends_at} );

	if ( $self->{datetime}->compare( $tags{end_date}, $self->{datetime}->long() ) < 0 ) {

		$tags{funding_terminated} = 1;
	}

      	if ( $self->{config} ) { 

		$tags{seed} = $self->seed();
	}

	$result->message( 'ALL OK.' );

	$result->content( \%tags );
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

		if ( $self->trim( $content ) =~ /Indiegogo/i ) {

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
