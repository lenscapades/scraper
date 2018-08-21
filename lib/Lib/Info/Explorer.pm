package Lib::Info::Explorer;

=head1 NAME

Lib::Info::Explorer - Class to manage explorer hash file database

=head1 SYNOPSIS

        use Lib::Info::Explorer;

        my $info = Lib::Info::Explorer->new();

	$info->get_flag();		# get explorer flag

	$info->set_flag();		# set explorer flag to 1

	$info->reset_flag();		# delete explorer flag

	$info->get_target();		# get explorer target

	$info->set_target();		# set current explorer target

	$info->reset_target();		# delete explorer target

        $info->get_targets();		# get list of targets for exploration

        $info->set_targets();		# save targets for exploration

=head1 DESCRIPTION

Class for explorer hash file database management.

Explorer::Run uses a flag to ensure that mysql database is queried only once per cycle.
Current explorer target is saved in $data->{target}.
A list of targets for Explorer::Run are accessed using $data->{targets}.

=cut

use Lib::Info;

@ISA = ( "Lib::Info" );

sub new {

	my $class = shift;

	my $self = {};

	bless( $self, $class );

	$self->{config} = shift
		or die __PACKAGE__ . "->new() missing config data"; 

	defined( $self->{config}->{db_file} )
		or die __PACKAGE__ . "->new() missing database file name"; 

	$self->{info} = Lib::Info::MLDBM->new(

			 $self->{config}->{db_file}

		) or die __PACKAGE__ . "->new() " . __PACKAGE__ . "::MLDBM->new() failed";

	return $self;
}

=pod

=head1 METHODS

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

Get explorer target.

=cut

sub get_target {

	my $self = shift;

	my $data = $self->get( qw(data) );

	return $data->{target};
}

=head2 set_target

Save current explorer target.

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

Delete explorer target.

=cut

sub reset_target {

	my $self = shift;

	my $data = $self->get( qw(data) );

	delete( $data->{target} );

	$self->set( qw(data), $data );
}

=head2 get_targets

Get list of targets for exploretion.

=cut

sub get_targets {

	my $self = shift;

	my $data = $self->get( qw(data) );

	return $data->{targets};
}

=head2 set_targets

Save targets for exploration.

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
