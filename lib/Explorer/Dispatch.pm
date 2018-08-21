package Explorer::Dispatch;

=pod

=head1 NAME

Explorer::Dispatch - class to dispatch explorer tasks

=head1 SYNOPSIS

	use Explorer::Dispatch;

	my $dispatch = Explorer::Dispatch->new( ... );

	$dispatch->run()

=head1 DESCRIPTION

=cut

use Explorer::Run;

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

	return $self;
}

=head1 METHODS

=head2 use_proxy

Proxy redirection is enabled by calling

	my $dispatch->use_proxy( 1 );

=cut

sub use_proxy {

	my $self = shift;

	if ( my $proxy = shift ) {

		$self->{use_proxy} = $proxy;
	}

	return $self->{use_proxy};
}

=head2 run

Call explorer->run() if task is well defined.

=cut

sub run {

	my $self = shift;

	if ( my @task = $self->task() ) {

		$self->explorer();

		$self->{explorer}->run();
	}
}

=head2 task

Verify that task is well defined.

=cut

sub task {

	my $self = shift;

	my @task = $self->{info}->get_task();

	if ( defined( $task[0] ) && $task[0] eq qw(retry) ) {

		return @task;
	}

	if ( defined( $task[0] ) && $task[0] eq qw(skip) ) {

		return @task;
	}

	if ( defined( $task[0] ) && $task[0] eq qw(explore) ) {

		return @task;
	}

	die __PACKAGE__ . "->task() unknown or undefined task";
}

=head2 explorer

Instantiate explorer and return reference.

=cut

sub explorer {

	my $self = shift;

	if ( !defined( $self->{explorer} ) ) {

		$self->{explorer} = Explorer::Run->new(

				$self->{config},

				$self->{logging},

				$self->{info},

			) or die __PACKAGE__ . "->new() Explorer::Run->new() failed";
	}

	$self->{explorer}->use_proxy( $self->use_proxy );

	return $self->{explorer};
}

=head2 retry

Retry task and update target.

Called in main class by function run().

=cut

sub retry {

	my $self = shift;

	$self->explorer();

	my $target = $self->{info}->get_target();

	if ( $target->{has_failed} ) {

		$target->{has_failed} += 1;
	}
	else {
		$target->{has_failed} = 1;
	}

	$self->{explorer}->set_target( $target );

	my @task = $self->{info}->get_task();

	shift @task;

	if ( $target->{has_failed} < $self->{config}->{task_max_fails} ) {

		$self->{logging}->entry( 1, "Retrying ..." );

		$self->{info}->set_task( qw(explore) );

		return;
	}

	$self->{info}->set_task( qw(skip:explore) );
}

=head2 skiPy

skip task and update target.

Called in main class by function run().

=cut

sub skip {

	my $self = shift;

	$self->explorer();

	my $target = $self->{info}->get_target();

	$target->{has_failed} = 0;

	if ( $target->{cnt_retry} ) {

		$target->{cnt_retry} += 1;
	}
	else {
		$target->{cnt_retry} = 1;
	}

	my @task = $self->{info}->get_task();

	shift @task;

	if ( $target->{cnt_retry} < $self->{config}->{task_max_retry} ) {

		$self->{logging}->entry( 1, "Skipping ..." );

		$self->{info}->set_task( qw(explore) );

		$self->{explorer}->push_targets( $target );

		$self->{explorer}->reset_target();

		return;
	}

	$self->{logging}->entry( 1, "Discarding ..." );

	$self->{info}->set_task( qw(explore) );

	$self->{explorer}->reset_target();
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
