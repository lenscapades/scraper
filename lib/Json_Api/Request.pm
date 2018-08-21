package Json_Api::Request;

=pod

=head1 NAME

Json_Api::Request - class to manage requests to server

=head1 SYNOPSIS

	use Json_Api::Request;

	my $json_api = Json_Api::Request->new( ... );

	$json_api->run()

=head1 DESCRIPTION

=cut

use Lib::Database::Json_Api;

use JSON;

use Data::Dumper;

sub new {

	my $class = shift;

	my $self = {};

	bless( $self, $class );

	$self->{config} = shift
		or die __PACKAGE__ . "->new() missing config data";

	$self->{logging} = shift
		or die __PACKAGE__ . "->new() missing logging object";

	$self->{info} = shift
		or die __PACKAGE__ . "->new() missing info object";

	$self->{database} = Lib::Database::Json_Api->new(

				$self->{config},
			
			) or die __PACKAGE__ . "->new() Lib::Database::Json_Api->new() failed";

	return $self;
}

=head1 METHODS

=cut
 
sub run {

	my $self = shift;

	my $query = shift
		or die __PACKAGE__ . "->run() missing argument";

	my $param = $self->get_query( $query );

	my $data = $self->get_data( $param );

	my $utf8_encoded_json_data = encode_json $data;

	return $utf8_encoded_json_data;
}

sub get_query {

	my $self = shift;

	my $query = shift
		or die __PACKAGE__ . "->get_query() missing argument";

	my $data = {};

	my @entries = split( '&', $query );

	foreach my $entry (@entries) {

		my @values = split( '=', $entry );

		$data->{$values[0]} = $values[1];
	}

	return $data;
}

sub get_data {

	my $self = shift;

	my $param = shift
		or die __PACKAGE__ . "->get_data() missing argument";

	my $data = undef;

	if ( defined( $param->{active_campaigns_by_day} ) ) {

		my $day = $param->{active_campaigns_by_day};

		if ( $self->sanitize_day( $day ) ) {

			$data = $self->get_active_campaigns_by_day( $day );
		}
	}

	return $data;
}

sub sanitize_day {

	my $self = shift;

	my $day = shift
		or die __PACKAGE__ . "->sanitize_day() missing argument";

	if ( $day =~ /^\d{4}-\d{2}-\d{2}$/ ) {

		return 1;
	}

	return 0;
}

sub get_active_campaigns_by_day {

	my $self = shift;

	my $day = shift
		or die __PACKAGE__ . "->get_active_campaigns_day() missing argument";

	my @labels = (
		"Kickstarter",
		"Indiegogo",
		"Startnext",
		"Exporo",
		"Seedmatch",
		"Kapilendo",
		"Companisto",
		"Bergfürst",
		"Deutsche Mikroinvest"
	);

	my $result = $self->{database}->select_active_campaigns_by_day( $day );

	my %data = (
		labels => \@labels,
		data => $result,
	);

	return \%data;
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
