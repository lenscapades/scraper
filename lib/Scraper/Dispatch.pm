package Scraper::Dispatch;

use Data::Dumper;

use Scraper::Run;

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

sub use_proxy {

	my $self = shift;

	if ( my $proxy = shift ) {

		$self->{use_proxy} = $proxy;
	}

	return $self->{use_proxy};
}

sub run {

	my $self = shift;

	if ( my @task = $self->task() ) {

		$self->scraper();

		$self->{scraper}->run();
	}
}

sub task {

	my $self = shift;

	my @task = $self->{info}->get_task();

	if ( defined( $task[0] ) && $task[0] eq qw(retry) ) {

		return @task;
	}

	if ( defined( $task[0] ) && $task[0] eq qw(skip) ) {

		return @task;
	}

	if ( defined( $task[0] ) && $task[0] eq qw(scrape) ) {

		return @task;
	}

	die __PACKAGE__ . "->task() unknown or undefined task";
}

sub scraper {

	my $self = shift;

	if ( !defined( $self->{scraper} ) ) {

		$self->{scraper} = Scraper::Run->new(

				$self->{config},

				$self->{logging},

				$self->{info},

       		 	) or die __PACKAGE__ . "->new() Scraper::Run->new() failed";
	}

	$self->{scraper}->use_proxy( $self->use_proxy );

	return $self->{scraper};
}

sub retry {

	my $self = shift;

	my @task = $self->{info}->get_task();

	shift @task;

	my $task_str = join( ":", @task );

	my $cnt = $self->{info}->set_task_failed( $task_str );

	if ( $cnt < $self->{config}->{task_max_fails} ) {

		$self->{logging}->entry( 1, "Retrying ..." );

		return $self->{info}->set_task( $task_str );
	}

	$self->{info}->reset_task_failed( $task_str );

	return $self->{info}->set_task( "skip:$task_str" );
}

sub skip {

	my $self = shift;

	$self->{logging}->entry( 1, "Skipping" );

	my @task = $self->{info}->get_task();

	shift @task;

	$self->{info}->set_task( join( ':', @task ) );

	if ( $task[0] eq qw(scrape) ) {

		my $target = $self->{info}->get_target();

		$self->scraper();

		$self->{scraper}->push_targets( $target );

		$self->{scraper}->reset_target();
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
