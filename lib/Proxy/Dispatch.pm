package Proxy::Dispatch;

use Data::Dumper;

use Proxy::Explore;

use Proxy::Scrape;

use Proxy::Check;

use Proxy::Update;

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

sub use_filter {

	my $self = shift;

	if ( my $filter = shift ) {

		$self->{use_filter} = $filter;
	}

	return $self->{use_filter};
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

		if ( $task[1] eq qw(explore) ) {

			$self->explore();

			$self->{explore}->run();
		}

		if ( $task[1] eq qw(scrape) ) {

			$self->scrape();

			$self->{scrape}->run();
		}

		if ( $task[1] eq qw(check) ) {

			$self->check();

			$self->{check}->run();
		}

		if ( $task[1] eq qw(update) ) {

			$self->update();

			$self->{update}->run();
		}
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

	if ( defined( $task[0] ) && $task[0] eq qw(proxy) ) {

		if ( !defined( $task[1] ) ) {

			if ( $self->{info}->update ) {

				$task[1] = qw(update);

				return $self->{info}->set_task( join( ":", @task ) );
			}
			else {

				$task[1] = qw(explore);

				return $self->{info}->set_task( join( ":", @task ) );
			}
		}

		return @task;
	}

	return undef;
}

sub explore {

	my $self = shift;

	if ( !defined( $self->{explore} ) ) {

		$self->{explore} = Proxy::Explore->new(

					$self->{config},

					$self->{logging},

					$self->{info}

       		 	) or die __PACKAGE__ . "->new() Proxy::Explore->new() failed";
	}

	$self->{explore}->use_proxy( $self->use_proxy );

	return $self->{explore};
}

sub scrape {

	my $self = shift;

	if ( !defined( $self->{scrape} ) ) {

		$self->{scrape} = Proxy::Scrape->new(

					$self->{config},

					$self->{logging},

					$self->{info}

        		) or die __PACKAGE__ . "->new() Proxy::Scrape->new() failed";
	}

	$self->{scrape}->use_filter( $self->use_filter );

	$self->{scrape}->use_proxy( $self->use_proxy );

	return $self->{scrape};
}

sub check {

	my $self = shift;

	if ( !defined( $self->{check} ) ) {

		$self->{check} = Proxy::Check->new(

					$self->{config},

					$self->{logging},

					$self->{info}

        		) or die __PACKAGE__ . "->new() Proxy::Check->new() failed";
	}

	return $self->{check};
}

sub update {

	my $self = shift;

	if ( !defined( $self->{update} ) ) {

		$self->{update} = Proxy::Update->new(

					$self->{config},

					$self->{logging},

					$self->{info}

			) or die __PACKAGE__ . "->new() Proxy::Update->new() failed";
	}

	return $self->{update};
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

	return $self->{info}->set_task( "skip:" . $task_str );
}

sub skip {

	my $self = shift;

	$self->{logging}->entry( 1, "Skipping" );

	my @task = $self->{info}->get_task();

	shift @task;

	$self->{info}->set_task( join( ':', @task ) );

	if ( $task[1] eq qw(explore) ) {

		$self->explore();

		$self->{explore}->set_next_task();
	}

	if ( $task[1] eq qw(scrape) ) {

		$self->scrape();

		$self->{scrape}->set_next_task();
	}

	if ( $task[1] eq qw(check) ) {

		$self->check();

		$self->{check}->set_next_task();
	}

	if ( $task[1] eq qw(update) ) {

		$self->update();

		$self->{update}->set_next_task();
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
