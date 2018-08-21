package Proxy;

=pod

=head1 NAME

Proxy - Class to manage proxy service data

=head1 SYNOPSIS

	use Proxy;

	my $proxy = Proxy->new( ... );

	$proxy->daemonize()		# run as daemon

	$proxy->kill(<signal>);		# send <signal> to daemon

=head1 DESCRIPTION

Proxy service data management.

=cut

use Lib::Config;

use Lib::Logging;

use Lib::Info::Proxy;

use Lib::Daemon;

use Lib::Dispatch;

use Proxy::Dispatch;

use Data::Dumper;

sub new {

	my $class = shift;

	my $self = {};

	bless( $self, $class );

	$self->config();

	$self->logging();

	my $named_parameters = shift;

	$self->verbose( $named_parameters->{verbose} );

	$self->target( $named_parameters->{target} );

	$self->use_proxy( $named_parameters->{proxy} );

	$self->use_filter( $named_parameters->{filter} );

	$self->update( $named_parameters->{update} );

	$self->info();

	return $self;
}

=head1 ATTRIBUTES

=head2 verbose

Do not be quiet, but print log to stdout.

Enable verbose mode by using verbose as a named parameter

	my $proxy = Proxy->new( { verbose => 1 } );

or by calling

	$proxy->verbose(1);

=cut

sub verbose {

	my $self = shift;

	if ( my $verbose = shift ) {

		$self->{verbose} = $verbose;
	}

	return $self->{verbose};
}

=head2 target

Do not scrape all proxy list targets, but use only a single specific target.

Set target by using target as a named parameter

	my $proxy = Proxy->new( { target => <target> } );

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

=head2 use_proxy

=cut

sub use_proxy {

	my $self = shift;

	if ( my $proxy = shift ) {

		$self->{use_proxy} = $proxy;
	}

	return $self->{use_proxy};
}

=head2 use_filter

=cut

sub use_filter {

	my $self = shift;

	if ( my $filter = shift ) {

		$self->{use_filter} = $filter;
	}

	return $self->{use_filter};
}

=head1 METHODS

=cut

=head2 daemonize

Instantiate daemon and call daemon run() with reference to $self.

=cut

sub daemonize {

	my $self = shift;

	my $pid = $self->{info}->get_pid();

	$self->{logging}->verbose( $self->verbose );

	if ( defined( $pid ) && $pid ne "" && kill( 0, $pid ) ) {

		print( "Another " . __PACKAGE__ . " is running (pid $pid).\nQuitting ...\n" );
		exit(1);
	}

	$self->{daemon} = Lib::Daemon->new(

			__PACKAGE__

		) or die __PACKAGE__ . "->daemonize() Lib::Daemon->new() failed";

	$self->{daemon}->run( \$self );
}

=head2 clear

Cleanup on daemon termination.

=cut 

sub clear {

	my $self = shift;

	# There is nothing to do here.
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

				__PACKAGE__

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

				$self->config

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

		$self->{info} = Lib::Info::Proxy->new(

				$self->config, {

					target => $self->target,

					update => $self->update,
				}

			) or die __PACKAGE__ . "->info() Lib::Info::Proxy->new() failed";
	}

	$self->{logging}->caller( $self->{info}->caller );

	return $self->{info};
}

=head2 dispatch 

Instantiate dispatch and return reference.

=cut 

sub dispatch {

	my $self = shift;

	if ( !defined($self->{dispatch}) ) {

		$self->{dispatch} = Lib::Dispatch->new(

			$self->config,

			$self->logging,

			$self->info, {

				caller => __PACKAGE__,
			}

		) or die __PACKAGE__ . "->dispatch() Lib::Dispatch->new() failed";
	}

	return $self->{dispatch};
}

=head2 proxy

Instantiate proxy and return reference.

=cut 

sub proxy {

	my $self = shift;

	if ( !defined($self->{proxy}) ) {

		$self->{proxy} = Proxy::Dispatch->new(

				$self->config,

				$self->logging,

				$self->info

			) or die __PACKAGE__ . "->proxy() Proxy::Dispatch->new() failed";
	}

	$self->{proxy}->use_filter( $self->use_filter );

	$self->{proxy}->use_proxy( $self->use_proxy );

	return $self->{proxy};
}

=head2 run 

Control of workflow.

=cut 

sub run {

	my $self = shift;

	$self->{logging}->verbose( $self->verbose );

	my @task = $self->{info}->get_task();

	if ( !@task ) {

		$self->dispatch();

		$self->{dispatch}->run();

		$self->{info}->set_task( "proxy" );
	}
	elsif ( $task[0] eq "sleep" ) {

		$self->dispatch();

		$self->{dispatch}->run();
	}
	elsif ( $task[0] eq "retry" ) {

		$self->proxy();

		$self->{proxy}->retry();
	}
	elsif ( $task[0] eq "skip" ) {

		$self->proxy();

		$self->{proxy}->skip();
	}
	elsif ( $task[0] eq "proxy" ) {

		$self->proxy();

		$self->{proxy}->run();
	}
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
