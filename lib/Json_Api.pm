package Json_Api;

=pod

=head1 NAME

Json_Api - class to manage API access to Scraper database

=head1 SYNOPSIS

	use Json_Api;

	my $json_api = Json_Api->new();

	$json_api->daemonize()		# run as daemon

	$json_api->kill(<signal>);	# send <signal> to daemon

=head1 DESCRIPTION

Modules included below are used for workflow control and accounting.

=cut

use Lib::Config;			# configuration data

use Lib::Logging;			# logging

use Lib::Info;				# hash file database

use Lib::Daemon;			# daemonize

use Json_Api::Socket;			# server socket

sub new {

	my $class = shift;

	my $self = {};

	bless( $self, $class );

	my $named_parameters = shift;

	$self->verbose( $named_parameters->{verbose} );

	$self->config();

	$self->logging();

	$self->info();

	return $self;
}

=head1 METHODS

=head2 verbose

Do not be quiet, but print log statements to stdout.

Verbose mode is enabled by using verbose as a named parameter

	my $json_api = Json_Api->new( { verbose => 1 } );

or by calling

	$json_api->verbose( 1 );


=cut

sub verbose {

	my $self = shift;

	if ( my $verbose = shift ) {

		$self->{verbose} = $verbose;
	}

	return $self->{verbose};
}

=head2 daemonize

Instantiate daemon and call daemon run() with reference to $self.

=cut

sub daemonize {

	my $self = shift;

	my $pid = $self->{info}->get_pid();

	$self->{logging}->verbose( $self->verbose );

	if ( defined( $pid ) && $pid ne "" && kill( 0, $pid ) ) {

		print "Another " . __PACKAGE__ . " is running (pid $pid).\nQuitting ...\n";

		exit(1);
	}

	$self->{daemon} = Lib::Daemon->new(

			__PACKAGE__,

		) or die __PACKAGE__ . "->daemonize() Lib::Daemon->new() failed";

	$self->{daemon}->run( \$self );
}

=head2 terminate 

Terminates daemon by calling daemon signal handler.

=cut

sub terminate {

	my $self = shift;

	if ( defined( $self->{daemon} ) ) {

		$self->{daemon}->signal_handler();
	}
}

=head2 clear

Cleanup on daemon termination.

=cut

sub clear {

	my $self = shift;

	# There is nothing to do here.
}

=head2 kill 

Send signal to daemon.

=cut

sub kill {

	my $self = shift;

	my $signal = shift
		or die __PACKAGE__ . "->kill() missing \$signal";

	my $pid = $self->{info}->get_pid();

	if ( defined( $pid ) && $pid ne "" ) {

		if ( kill( $signal, $pid ) ) {

			print "Send signal $signal to " . __PACKAGE__ . " (pid $pid)\n";

			$self->{logging}->entry( 1, "Send signal $signal to " . __PACKAGE__ . " (pid $pid)" );

			return;
		}
	}

	print "Nothing to kill here ...\n";
}

=head2 config

Instantiate config, get and return config data.

=cut

sub config {

	my $self = shift;

	if ( !defined($self->{config_parameters}) ) {

		my $config = Lib::Config->new(

				__PACKAGE__,

			) or die __PACKAGE__ . "->config() Lib::Config->new() failed";

		$self->{config_parameters} = $config->get();
	}

	return $self->{config_parameters};
}

=head2 logging

Instantiate logging and return reference.

=cut

sub logging {

	my $self = shift;

	if ( !defined($self->{logging}) ) {

		$self->{logging} = Lib::Logging->new(

				$self->config,

			) or die __PACKAGE__ . "->logging() Lib::Logging->new() failed";
	}

	return $self->{logging};
}

=head2 info

Instantiate info and return reference.

=cut 

sub info {

	my $self = shift;

	if ( !defined($self->{info}) ) {

		$self->{info} = Lib::Info->new(

				$self->config

			) or die __PACKAGE__ . "->info() Lib::Info->new() failed";
	}

	$self->{logging}->caller( __PACKAGE__ );

	return $self->{info};
}

=head2 json_api

json_api

=cut

sub json_api {

        my $self = shift;

        if ( !defined( $self->{json_api} ) ) {

                $self->{json_api} = Json_Api::Socket->new(

				$self->config,

				$self->logging,

				$self->info,

			) or die __PACKAGE__ . "->json_api() Json_Api::Socket->new() failed";

        }

        return $self->{json_api};
}

=head2 run 

Control workflow.

=cut 

sub run {

	my $self = shift;

	$self->{logging}->verbose( $self->verbose );

	$self->json_api();

	$self->{json_api}->run();
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
