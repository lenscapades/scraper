package Scraper::Parser::Kickstarter;

=pod

=head1 NAME

Scraper::Parser::Kickstarter - Class to parse kickstarter.com campaign data.

=head1 SYNOPSIS

	use Scraper::Parser::Kickstarter;

	my $parser = Scraper::Parser::Kickstarter->new();

	$parser->scrape( $result, $dataref );

=head1 DESCRIPTION

Parse kickstarter.com campaign data.

=cut

use Lib::Parser;

@ISA = ( "Lib::Parser" );

use Mojo::DOM58;

use JSON::PP;

use URI::Escape;

use HTML::Entities;

use Encode qw(encode decode);

use Data::Dumper;

=head1 METHODS

=head2 categories 

Return kickstarter.com main categroy slug.

=cut

sub categories {

	my $self = shift;

	if ( !@_ ) { 

		die __PACKAGE__ . "->categories() missing argument";
	}

	my $category_id = shift;

	my %categories = (
		1	=> 'Art',
		3	=> 'Comics',
		6	=> 'Dance',
		7	=> 'Design',
		9	=> 'Fashion',
		10	=> 'Food',
		11	=> 'Film & Video',
		12	=> 'Games',
		13	=> 'Journalism',
		14	=> 'Music',
		15	=> 'Photography',
		16	=> 'Technology',
		17	=> 'Theater',
		18	=> 'Publishing',
		26	=> 'Crafts',
	);

	if ( defined( $categories{$category_id} ) ) {

		return $categories{$category_id};
	}

	return undef;
}

=head2 scrape 

Scrape kickstarter.com campaign data.

=cut

sub scrape {

	my $self = shift;

	my $result = shift
		or die __PACKAGE__ . "->scrape() missing argument";

	my $data = shift
		or die __PACKAGE__ . "->scrape() missing argument";

	my $dom = Mojo::DOM58->new( $self->trim( $data ) );

	my $html = $dom->at( 'html' );

	if ( !$html ) {

		$result->error( 1 );

		$result->message( 'Missing HTML data.' );

		$result->content( $data );

		return;
	}

	if ( my $lang = $html->attr( 'lang' ) ) {

		$self->locale( $lang );
	}
	else {
		$self->locale( 'en-US' );
	}

	undef $html;

	my $sdata = undef;

	$dom->find( 'script' )->each( sub {

		my $script = shift;

		if ( $script =~ /window\.current_project\s*=\s*"(.*?(?=";\s*window))";/ ) {

			$sdata = decode_entities( $1 );

			$sdata =~ s/\\\\/\\/g;

			return;
		}
	} );

	undef $dom;

	undef $data;

	$sdata = encode_entities( $sdata, '\x{10}-\x{16}' );
	$sdata = encode_entities( $sdata, '\x{24}' );

	my $href = undef;

	eval {
		$href = decode_json( encode( 'UTF-8', $sdata ) );
		1;

	} or do {

		$result->error( 1 );

		chomp( $@ );

		$result->message( $@ );

		$result->content( $sdata );

		return;
	};

	if ( !defined( $href ) ){

		$result->error( 1 );

		$result->message( 'Missing JSON data.' );

		$result->content( $sdata );

		return;
	}

	undef $sdata;

	# use uri_unescape on $href values if necessary

	my %tags = ();

	$tags{name}		= $href->{name};

	if ( my $category = $self->categories( $href->{category}->{id} ) ) {

		$tags{category} = $category;
	}
	else {

		$tags{category} = $self->categories( $href->{category}->{parent_id} );
	}

	$tags{currency}		= $href->{currency};

	$tags{funding_type}	= "fixed";

	$tags{goal_amount}	= $href->{goal}; 

	$tags{raised_amount}	= $href->{pledged};

	$tags{funders}		= $href->{backers_count};
		
	$tags{start_date}	= $self->date( $href->{launched_at} );

	$tags{end_date}		= $self->date( $href->{deadline} );

	if ( ( $self->{datetime}->compare( $tags{end_date}, $self->{datetime}->long() ) < 0 )
		|| ( defined( $href->{state} ) && ( $href->{state} eq qw(canceled) || $href->{state} eq qw(suspended) ) ) ) {

		$tags{funding_terminated} = 1;
	}

	if ( $self->{config} ) { 

		$tags{seed} = $self->seed();
	}

	$result->message( 'All OK.' );

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

		if ( $self->trim( $content ) =~ /^The page you were looking for doesn't exist \(404\)/ ) {

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
