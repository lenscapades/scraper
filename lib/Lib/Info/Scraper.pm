package Lib::Info::Scraper;

=head1 NAME

Lib::Info::Scraper - Class to manage scraper hash file database

=head1 SYNOPSIS

        use Lib::Info::Scraper;

        my $info = Lib::Info::Scraper->new();

=head1 DESCRIPTION

Class for scraper hash file database management.
Inherits from Lib::Info.

=cut

use Lib::Info;

@ISA = ( "Lib::Info" );

use Switch;

use Data::Dumper;

sub new {

	my $class = shift;

	my $config = shift
		or die __PACKAGE__ . "->new() missing argument";

	my $self = $class->Lib::Info::new( $config );

	$self->{config} = $config;

	my $named_parameters = shift;

	$self->named_parameters( $named_parameters );

	$self->set_db_file();

	return $self;
}

=pod

=head1 METHODS

=head2 named_parameters

Set named parameters.

=cut

sub named_parameters {

	my $self = shift;

	my $named_parameters = shift;

	my $target = $named_parameters->{target};

	if ( !$target ) {

		print "No target subset specified.\nQuitting ...\n";

		exit(1);
	}
	
	$self->{target} = lc( $target );

	return;
}

=head2 target

=cut

sub target {

	my $self = shift;

	if ( my $target = shift ) {

		$self->{target} = $target;
	}

	return $self->{target};
}

=head2 caller

=cut

sub caller {

	my $self = shift;

	my $target = $self->target;

	switch ( $target ) {

		case 'daily'		{ return 'Daily'; }

		case 'new'		{ return 'New'; }

		case 'ending'		{ return 'Ending'; }

		case 'query'		{ return 'Query'; }
	}

	die __PACKAGE__ . "->caller() failed: not implemented (maybe a typo)";
}

sub set_db_file {

	my $self = shift;

	$self->{config}->{db_file} .= "/" . lc( $self->caller ) . ".db";

	$self->file( $self->{config} );
}

=head2 get_flag

Get explorer flag.

=cut

sub get_flag {

	my $self = shift;

	my $data = $self->get( qw(data) );

	return $data->{flag};
}

=head2 set_flag

Set explorer flag to 1.

=cut

sub set_flag {

	my $self = shift;

	my $data = $self->get( qw(data) );

	$data->{flag} = 1;

	$self->set( qw(data), $data );
}

=head2 reset_flag

Delete explorer flag.

=cut

sub reset_flag {

	my $self = shift;

	my $data = $self->get( qw(data) );

	$data->{flag} = 0;

	$self->set( qw(data), $data );
}

=head2 get_target

Get Scraper target.

=cut

sub get_target {

	my $self = shift;

	my $data = $self->get( qw(data) );

	return $data->{target};
}

=head2 set_target

Save Scraper target.

=cut

sub set_target {

	my $self = shift;

	my $target = shift
		or die __PACKAGE__ . "->set_target() missing argument"; 

	my $data = $self->get( qw(data) );

	$data->{target} = $target;

	$self->set( qw(data), $data );
}

=head2 reset_target

Delete Scraper target.

=cut

sub reset_target {

	my $self = shift;

	my $data = $self->get( qw(data) );

	delete( $data->{target} );

	$self->set( qw(data), $data );
}

=head2 get_targets

Get list of targets.

=cut

sub get_targets {

	my $self = shift;

	my $data = $self->get( qw(data) );

	return $data->{targets};
}

=head2 set_targets

Save targets.

=cut

sub set_targets {

	my $self = shift;

	my $targets = shift
		or die __PACKAGE__ . "->set_targets() missing argument"; 

	my $data = $self->get( qw(data) );

	$data->{targets} = $targets;

	$self->set( qw(data), $data );
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
