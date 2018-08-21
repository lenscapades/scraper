package Explorer::Parser::Indiegogo;

=pod

=head1 NAME

Explorer::Parser::Indiegogo - Class to parse indiegogo.com exploration data.

=head1 SYNOPSIS

=head1 DESCRIPTION

Parse indiegogo.com exploration data.

Inherits from base class Lib::Parser.

=cut

use Lib::Parser;

@ISA = ( "Lib::Parser" );

use JSON::PP;

use Data::Dumper;

=head1 METHODS

=head2 explore 

Find active campaigns and parse campaign name, uri (request) and end date.

=cut

sub explore {

	my $self = shift;

	my $result = shift
		or die __PACKAGE__ . "->explore() missing argument";

	my $data = shift
		or die __PACKAGE__ . "->explore() missing argument";

	if ( $data !~ /^\{.*\}$/ ) {

		$result->error(1);

		$result->message( "Malformed JSON string." );

		$result->content( $data );

		return;
	}

	my $prefix = 'https://www.indiegogo.com';

	$self->locale( 'en-US' );

	my @entries = ();

	my $href = decode_json( $data );

	foreach my $val ( @{$href->{campaigns}} ) {

		last unless ref( $val ) eq "HASH";

		my %tags = ();

		$tags{request} = $self->uri( $val->{url}, $prefix );

		$tags{name} = $val->{title};

		$tags{category} = $val->{category_name};

		$tags{currency} = $val->{currency_code};

		$tags{raised_amount} = $self->amount( $val->{balance} );

		$tags{end_date} = $self->end_date( $val->{amt_time_left} );

       		if ( $self->{config} ) { 

			$tags{seed} = $self->seed();
		}

		push( @entries, \%tags );
	}

	$result->content( \@entries );

	if ( my $per_page = $self->per_page ) {

		$result->extra( { per_page => $per_page } );
	}
}

sub per_page {

	my $self = shift;

	if ( my $request = $self->request ) {

		if ( $request =~ /\&per_page=(\d+)/ ) {

			return $1;
		}
	}

	return undef;
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
