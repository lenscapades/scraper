package Explorer::Run;

=pod

=head1 NAME

Explorer::Run - Class to perform target exploration.

=head1 SYNOPSIS

	use Explorer::Run;

	my $explorer = Explorer::Run->new( ... );

	$explorer->run();


=head1 DESCRIPTION

Class for target exploration.

=cut

use Lib::Database::Explorer;

use Lib::Proxy;

use Lib::Get;

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

	$self->{database} = Lib::Database::Explorer->new(

				$self->{config},
			
			) or die __PACKAGE__ . "->new() Lib::Database::Explorer->new() failed";

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

Control workfow.

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

	if ( $target->{page_number} < 0 ) {

		$self->{logging}->entry( 1,  "Exploring $target->{target} ..." );
	}
	else {
		$self->{logging}->entry( 1,  "Exploring $target->{target} page $target->{page_number} ..." );
	}

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
		or die __PACKAGE__ . "->factory_target() missing argument";

	$self->{info}->set_target( $target );
}

=head2 reset_target

Reset target in hash file database.

=cut

sub reset_target {

	my $self = shift;

	$self->{info}->reset_target();
}

sub get_targets {

	my $self = shift;

	my $targets = $self->{info}->get_targets();

	if ( !@$targets ) {

		my $flag = $self->{info}->get_flag();

		if ( !$flag ) {

			$self->{info}->set_flag();

			$entries = $self->{database}->select_all_targets();

			if ( !@$entries ) {

				die __PACKAGE__ . "->get_targets() database error";
			}

			foreach my $entry ( @$entries ) {

				push( @$targets, $self->factory_target( qw(explore), $entry ) );
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

sub factory_target {

	my $self = shift;

	my $type = shift
		or die __PACKAGE__ . "->factory_target() missing argument";

	my $target = shift
		or die __PACKAGE__ . "->factory_target() missing argument";

	my $entry = {

		id		=> $target->{id},

		target		=> $target->{name},

		type		=> $type,

		request		=> $target->{request},

		page_number	=> $self->get_target_first_page( $target->{request} ),

		referer		=> $target->{referer},

		time_zone	=> $target->{time_zone},

	};

	return $entry;
}

sub set_retry {

	my $self = shift;

	$self->{info}->set_task( "retry:explore" );
}

sub set_skip {

	my $self = shift;

	$self->{info}->set_task( "skip:explore" );
}

=head2 set_sleep

Set task to sleep.

=cut

sub set_sleep {

	my $self = shift;

	$self->{info}->set_task( "sleep" );
}

sub get_target_first_page {

	my $self = shift;

	my $request = shift
		or die __PACKAGE__ . "->get_target_first_page() missing argument";

	if ( $request =~ /\$page=(\d)/ ) {

		return $1;
	}

	return -1;
}

sub factory_next_page {

	my $self = shift;

	my $target = shift
		or die __PACKAGE__ . "->get_next_page() missing argument";

	if ( $target->{page_number} >= 0 ) {

		return ++$target->{page_number};
	}

	return $target->{page_number};
}

sub report {

	my $self = shift;

	my $results = shift
		or die __PACKAGE__ . "->report() missing argument";

	my $cnt = scalar @$results;

	if ( $cnt > 1 ) {

		$self->{logging}->entry( 2, "Found " . $cnt . " targets" );
	}
	elsif ( $cnt < 1 )  {

		$self->{logging}->entry( 2, "No targets found" );
	}
	else {
		$self->{logging}->entry( 2, "Found " . $cnt . " target" );
	}

	return $cnt;
}

sub get_results {

	my $self = shift;

	my $results = shift
		or die __PACKAGE__ . "->get_results() missing argument";

	my $extra = shift;

	my $target = shift
		or die __PACKAGE__ . "->get_results() missing argument";

	my $cnt = $self->report( $results );

	if ( $cnt > 0 ) {

		my $new_campaign = $self->{database}->update_database( $target, $results );

		if ( $new_campaign > 1 ) {

			$self->{logging}->entry( 3, "Created $new_campaign new campaigns" );
		}
		elsif ( $new_campaign < 1 ) {

			$self->{logging}->entry( 3, "No new campaigns created" );
		}
		else {
			$self->{logging}->entry( 3, "Created " . $new_campaign . " new campaign" );
		}
	}

	if ( defined( $extra->{per_page} ) ) {

		if ( $cnt == $extra->{per_page} ) {

			return 0;
		}

		return 1;
	}

	return 0;
}

sub push_targets {

	my $self = shift;

	my $target = shift
		or die __PACKAGE__ ."->push_targets() missing argument";

	my $targets = $self->{info}->get_targets();

	push( @$targets, $target );

	$self->{info}->set_targets( $targets );
}

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

				daemon => qw(Explorer),
			},

		) or die __PACKAGE__ . "->get() Lib::Get->new() failed";

	my $response = $get->get_response( $target );

	if ( !$response->is_error ) {

		if ( my $response_content = $response->content() ) {

			my $result = $get->get_content( $response_content );

			if ( $result->is_error ) {

				$self->{proxy}->update_proxy( $target->{proxy}, 0 );

				$self->{logging}->entry( 1, $result->message );

				$self->set_retry();

				return;
			}
			else {
				my $result_content = $result->content();

				my $result_extra = $result->extra();

				$self->{proxy}->update_proxy( $target->{proxy}, 1 );

				if ( @$result_content ) {

					my $last_page = $self->get_results( 
						$result_content, 
						$result_extra, 
						$target
					);

					if ( $last_page ) {

						my @task = $self->{info}->get_task();

						$self->reset_target();

						return;
					}

					my $next_page = $self->factory_next_page( $target );

					if ( $next_page > 0 ) {

						$target->{has_failed} = 0;

						$self->push_targets( $target );	
					}

					$self->reset_target();

					return;
				}
				else  {
					$self->{logging}->entry( 1, "No targets found" );

					$self->reset_target();

					return;
				}
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
		$self->{proxy}->update_proxy( $target->{proxy}, 0 );

		my $response_message = $response->message;

		if ( $self->{logging}->level < 2 ) {

			$self->{logging}->entry( 1, $response_message );
		}

		if ( $response_message =~ /^403/ || $response_message =~ /^5/ ) {

				$self->set_retry();

				return;
		}
		else {
			$self->set_skip();

			return;
		}
	}
}

1;
