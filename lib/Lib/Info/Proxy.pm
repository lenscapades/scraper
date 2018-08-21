package Lib::Info::Proxy;

=head1 NAME

Lib::Info::Proxy - Class to access proxy hash file database

=head1 SYNOPSIS

        use Lib::Info::Proxy;

        my $info = Lib::Info::Proxy->new();

        $info->set_targets();		# save targets for exploration, scrapig and checking

        $info->get_targets();		# get targets for exploration, scrapig and checking

        $info->set_update_date();		# save date of last update

        $info->get_update_date();		# get date of last update

=head1 DESCRIPTION

Hash file database access.

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

	my $update = $named_parameters->{update};

	if ( defined( $target ) && defined( $update ) ) {

		print "Can not check target and update database at once.\nQuitting ...\n";

		exit(1);
	}

	if ( $update ) {

		$self->{update} = $update;

		return;
	}

	if ( !$target ) {

		print "No proxy target specified.\nQuitting ...\n";

		exit(1);
	}
	else {
		$target = lc( $target );

		my $proxy_targets = $self->{config}->{proxy_targets};

		foreach my $proxy_target ( @$proxy_targets ) {

			if ( $proxy_target->{uri} =~ /.+www\.([^\.]+)/ ) {

				my $uri_target = $1;

				if ( $target =~ /^$uri_target$/i ) {

					$self->{target} = $target;

					last;
				}
			}
		}
	}

	if ( !$self->{target} ) {

		print "Unknown proxy service list (maybe a typo).\nQuitting ...\n";
		exit(1);
	}

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

=head2 update

=cut

sub update {

	my $self = shift;

	if ( my $update = shift ) {

		$self->{update} = $update;
	}

	return $self->{update};
}

=head2 caller

=cut

sub caller {

	my $self = shift;

	my $target = $self->target;

	my $update = $self->update;

	if ( $target && $update ) {

		die __PACKAGE__ . "->caller() not allowed.";
	}

	if ( $update ) {

		return 'Update';
	}

	switch ( $target ) {

		case 'sslproxies'	{ return 'SSLProxies'; }

		case 'freeproxylists'	{ return 'FreeProxyLists'; }
	}

	die __PACKAGE__ . "->caller() failed: not implemented (maybe a typo)";
}

sub set_db_file {

	my $self = shift;

	$self->{config}->{db_file} .= "/" . lc( $self->caller ) . ".db";

	$self->file( $self->{config} );
}

sub get_proxy_targets {

	my $self = shift;

	if ( $self->update ) {

		return undef;
	}

	my $key = $self->caller();

	my $proxy_targets = $self->{config}->{proxy_targets};

	foreach my $proxy_target ( @$proxy_targets ) {

		if ( $proxy_target->{uri} =~ /.+www\.([^\.]+)/ ) {

			my $uri_target = $1;

			if ( $key =~ /^$uri_target$/i ) {

				return [ $proxy_target ];
			}
		}
	}

	die __PACKAge__ . "->get_proxy_target() could not match target";
}

=head2 get_targets

=cut

sub get_targets {

	my $self = shift;

	my $type = shift
		or die __PACKAGE__ . "->get_targets() missing argument";

	my $data = $self->get( qw(data) );

	return $data->{$type}->{targets};
}

=head2 set_targets

=cut

sub set_targets {

	my $self = shift;

	my $type = shift
		or die __PACKAGE__ . "->set_targets() missing argument";

	my $targets = shift
		or die __PACKAGE__ . "->set_targets() missing argument"; 

	my $data = $self->get( qw(data) );

	$data->{$type}->{targets} = $targets;

	$self->set( qw(data), $data );

	return $data->{$type}->{targets};
}

=head2 get_update_date

Get date ot last update.

=cut

sub get_update_date {

	my $self = shift;

	my $data = $self->get( qw(data) );

	return $data->{update};
}

=head2 set_update_date

Save date ot last update.

=cut

sub set_update_date {

	my $self = shift;

	my $datetime = shift
		or die __PACKAGE__ . "->set_update_date() missing argument";

	my $data = $self->get( qw(data) );

	$data->{update} = $datetime;

	$self->set( qw(data), $data );
}

=head2 reset_update_date

Delete update date from hash file database.

=cut

sub reset_update_date {

	my $self = shift;

	my $data = $self->get( qw(data) );

	delete( $data->{update} );

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
