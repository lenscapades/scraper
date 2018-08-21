package Scraper::Run;

=pod

=head1 NAME

Scraper::Run - Class to perform target scraping 

=head1 SYNOPSIS

	use Scraper::Run;

	my $scraper = Scraper::Run->new( ... );

	$scraper->run();


=head1 DESCRIPTION

Class for target scraping.

=cut

use Lib::Database::Scraper;

use Lib::Proxy;

use Lib::Get;

use Switch;

use Encode qw(encode);

use Data::Dumper;

sub new {

	my $class = shift;

	my $self = {};

	bless( $self, $class );

	$self->{config}	= shift
		or die __PACKAGE__ . "->new() missing config data";

	$self->{logging} = shift
		or die __PACKAGE__ . "->new() missing logging object";

	$self->{info} = shift
		or die __PACKAGE__ . "->new() missing info object";

	$self->{proxy} = Lib::Proxy->new(

				$self->{config},

				$self->{info},
			
			) or die __PACKAGE__ . "->new() Lib::Proxy->new() failed";

	$self->{database} = Lib::Database::Scraper->new(

				$self->{config},
			
			) or die __PACKAGE__ . "->new() Lib::Database::Scraper->new() failed";

	return $self;
}

=head1 ARGUMENTS

=head2 use_proxy

=cut

sub use_proxy {

	my $self = shift;

	if ( my $proxy = shift ) {

		$self->{use_proxy} = $proxy;
	}

	return $self->{use_proxy};
}

=head1 METHODS

=head2 run

Control workflow.

Use target from hash file database or select target from mysql database if there is no target in hash file database.
If there is no more target to scrape, go to sleep.

=cut

sub run {

	my $self = shift;

	my $target = $self->get_target();

	if ( !$target ) {

		$target = $self->get_targets();

		if ( $target ) {

			$self->set_target( $target );
		}
		else {
			$self->set_sleep();

			return;
		}
	}

	$self->{logging}->entry( 1, "Scraping campaign \"" . encode( 'UTF-8', $target->{name} ) . "\" of platform $target->{target}" );

	$self->get( $target );
}

=head2 get_target

Get target from hash file database.

=cut

sub get_target {

	my $self = shift;

	return $self->{info}->get_target();
}

=head2 set_target

Save target to hash file database.

=cut

sub set_target {

	my $self = shift;

	my $target = shift
		or die __PACKAGE__ . "->set_target() missing argument";

	$target->{type} = qw(scrape);

	$self->{info}->set_target( $target );
}

=head2 reset_target

Reset target in hash file database.

=cut

sub reset_target {

	my $self = shift;

	my $target = $self->get_target();

	if ( $target ) {

		$self->{database}->update_failure( $target );
	}

	$self->{info}->reset_target();

	$self->{info}->reset_task_failed( qw(scrape) );
}


sub get_targets {

	my $self = shift;

	my $targets = $self->{info}->get_targets();

	if ( defined( $targets) && !@$targets ) {

		my $flag = $self->{info}->get_flag();

		if ( !$flag ) {

			$self->{info}->set_flag();

			switch ( $self->{info}->caller ) {

				case 'Daily'	{ $entries = $self->{database}->select_all_targets_daily(); }

				case 'New'	{ $entries = $self->{database}->select_all_targets_new(); }

				case 'Ending'	{ $entries = $self->{database}->select_all_targets_ending(); }

				case 'Query'	{ $entries = $self->{database}->select_all_targets_query(); }
			}

			if ( !@$entries ) {

				die __PACKAGE__ . "->get_targets() database error";
			}

			foreach my $entry ( @$entries ) {

				push( @$targets, $entry );
			}
		}
		else {
			$self->{info}->reset_flag();

			return undef;
		}
	}

	$target = shift( @$targets );

	$self->{info}->set_targets( $targets );

	return $target;
}

=head2 set_retry

Set task to retry.

=cut

sub set_retry {

	my $self = shift;

	$self->{info}->set_task( "retry:scrape" );
}

=head2 set_skip

Set task to skip.

=cut

sub set_skip {

	my $self = shift;

	$self->{info}->set_task( "skip:scrape" );
}

=head2 set_sleep

Set task to sleep.

=cut

sub set_sleep {

	my $self = shift;

	$self->{info}->set_task( "sleep" );
}

=head2 report

Report result status.

=cut

sub report {

	my $self = shift;

	my $result = shift
		or die __PACKAGE__ . "->report() missing argument";

	if ( keys %$result ) {

		$self->{logging}->entry( 1, "Succeeded" );

		return 1;
	}
	else {
		$self->{logging}->entry( 1, "Failed" );

		return 0;
	}
}

=head2 set_not_found

Mark target as not found in database.

=cut

sub set_not_found {

	my $self = shift;

	my $target = shift
		or die __PACKAGE__ . "->set_not_found() missing argument";

	$self->{logging}->entry( 1, "Target not found" );

	$self->{database}->not_found_result( $target );
}

=head2 get_result

Save result to mysql database.

=cut

sub get_result {

	my $self = shift;

	my $target = shift
		or die __PACKAGE__ . "->get_results() missing argument";

	my $result = shift
		or die __PACKAGE__ . "->get_results() missing argument";

	if ( $self->report( $result ) ) {

		$self->{database}->update_result( $target, $result );
	}
}

sub push_targets {

	my $self = shift;

	my $target = shift
		or die __PACKAGE__ ."->push_targets() missing argument";

	my $targets = $self->{info}->get_targets();

	push( @$targets, $target );

	$self->{info}->set_targets( $targets );
}

=head2 get

Perform request and handle response data.

=cut

sub get {

	my $self = shift;

	my $target = shift
		or die __PACKAGE__ . "->get() missing argument";

	if ( $self->use_proxy ) {

		$target->{proxy} = $self->{proxy}->get_proxy();
	}

	my $get = Lib::Get->new(

			$self->{config},

			$self->{logging}, {

				proxy => defined( $target->{proxy} ),

				agent => 1, 

				logging => 1,

				daemon => qw(Scraper),
			},

		) or die __PACKAGE__ . "->get() Lib::Get->new() failed";

	my $response = $get->get_response( $target );

	if ( !$response->is_error ) {

		if ( my $response_content = $response->content() ) {

			my $result = $get->get_content( $response_content );

			if ( $result->is_error ) {

				if ( $result->message =~ /^404/ ) {

					$self->{proxy}->update_proxy( $target->{proxy}, 1 );

					$self->set_not_found( $target );

					$self->reset_target();

					return;
				}
				elsif ( $result->message =~ /^Fundraiser/ ) {

					$self->{proxy}->update_proxy( $target->{proxy}, 1 );

					$self->set_not_found( $target );

					$self->reset_target();

					return;
				}
				else {

					$self->{proxy}->update_proxy( $target->{proxy}, 0 );

					$self->{logging}->entry( 1, $result->message );

					$self->set_retry();

					return;
				}
			}
			else {

				$self->{proxy}->update_proxy( $target->{proxy}, 1 );

				$self->get_result( 
					$target,
					$result->content, 
				);

				$self->reset_target();

				return;
			}
		}
		else {
			$self->{proxy}->update_proxy( $target->{proxy}, 0 );

			$self->{logging}->entry( 1, "Unknown error" );

			$self->set_retry();

			return;
		}
	}
	else {

		my $response_message = $response->message;

		if ( $response_message =~ /^404/ ) {

			if ( my $response_content = $response->content() ) {

				if ( $get->validate_not_found( $response_content ) ) {

					$self->{proxy}->update_proxy( $target->{proxy}, 1 );

					$self->set_not_found( $target );

					$self->reset_target();

					return;
				}
			}
		}

		$self->{proxy}->update_proxy( $target->{proxy}, 0 );

		$self->{logging}->entry( 1, $response_message );

		if ( $response_message =~ /^403/ || $response_message =~ /^5/ ) {

			$self->set_retry();
		}
		else {

			$self->set_skip();
		}

		return;
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
