package Lib::Agent;

use Data::Dumper;

=pod

=head1 NAME

Lib::Agent - Class to manage user agent headers and cookie_jars

=head1 SYNOPSIS

	use Lib::Agent;

	my $agent = Lib::Agent->new();

	my $this_agent = $agent->any( {
				locale => 'de_DE'
			} );

	$this_agent->agent();		# returns user agent string

	$this_agent->headers();		# returns http headers hash

	$this_agent->cookie_jar();	# returns HTTP::Cookies object

=head1 DESCRIPTION

Class for user agent header and cookie_jar management.

=cut

use Lib::Info::MLDBM;

use HTTP::Cookies;

use Digest::MD5 qw(md5_hex);

use URI::Escape;

sub new {

	my $class = shift;

	my $self = {};

	bless( $self, $class );

	$self->{config} = shift
		or die __PACKAGE__ . "->new() missing argument";

	$self->{info} = Lib::Info::MLDBM->new(
				$self->{config}->{run_dir} . "/agents.db"
			)
		or die __PACKAGE__ . "->new() Lib::Info::MLDBM->new() failed";

	$self->factory_agents();

	$self->{this_agent} = undef;

	return $self;
}

=head1 METHODS

=head2 get_version_data

=cut

sub get_version_data {

	my $self = shift;

	my $file = $self->{config}->{config_dir} . "/lib/Lib/Agent/version.data"; 

	if ( -e $file ) {

		my @version = ();

		open( FILE, "<", $file );

		while ( <FILE> ) {

			chomp;

			push( @version, $_ );
		}

		close( FILE );

		return \@version;
	}
	else {
		die __PACKAGE__ . "->get_version_data() could not find file";
	}
}

=head2 get_agents

=cut

sub get_agents {

	my $self = shift;

	my $agents = $self->{info}->get( qw(agents) );

	my $agents_hash = $self->{info}->get( qw(agents_hash) );

	return ( $agents, $agents_hash );
}

=head2 set_agents

=cut

sub set_agents {

	my $self = shift;

	my $agents = shift
		or die __PACKAGE__ . "->set_agents() missing argument";

	my $agents_hash = shift
		or die __PACKAGE__ . "->set_agents() missing argument";

	$self->{info}->set( qw(agents), $agents );

	$self->{info}->set( qw(agents_hash), $agents_hash );

	return ( $agents, $agents_hash );
}

=head2 factory_agents

Set up and return array of user agent parameters.

=cut

sub factory_agents {

	my $self = shift;

	( $self->{agents}, $self->{agents_hash} ) = $self->get_agents();

	if ( !$self->{agents} ) {

		my %agents_index = ();

		my @agents = ();

		my $versions = $self->get_version_data();

		my $idx = 0;

		foreach my $version ( @$versions ) {

			my $md5_hash = md5_hex( $version );

			if ( !defined( $agents_hash{$md5_hash}->{index} ) ) {

				$agents_hash{$md5_hash} = { index => $idx };

				my %agent = (
					headers		=> $self->headers( $version ),
					cookie_jar	=> $self->cookies( $md5_hash ),
				);

				$agents[$idx] = \%agent;

				$idx++;
			}
		}

		( $self->{agents}, $self->{agents_hash} ) = $self->set_agents( \@agents, \%angents_index );
	}
}

sub headers {

	my $self = shift;

	my $agent = shift
		or die __PACKAGE__ . "->headers() missing argument";

	$header = {
		agent	=> $agent,
		headers	=> {
			'Accept'                => '*/*',
			'Accept-Language'       => 'de,en-US;q=0.7,en;q=0.3',
			'Accept-Encoding'       => 'gzip, deflate, br',
			'HTTP_ACCEPT'		=> 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
			'HTTP_CACHE_INFO' 	=> $agent,
			'HTTP_CONNECTION'	=> 'keep-alive',
			'SERVER_PROTOCOL'	=> 'HTTP/1.1',
		}
	};

	return $header;
}

=head2 locale 

Factory locale string.

=cut

sub locale {

	my $self = shift;

	my $code = shift
		or die __PACKAGE__ . "->locale() missing argument";

	my $locale = 'de,en-US;q=0.7,en;q=0.3';

	if ( $code eq 'de_DE' ) {

		$locale = 'de-DE,de;q=0.5';
	}

	if ( $code eq 'en_US' ) {

		$locale = 'en-US,en;q=0.5';
	}

	return $locale;
}

=head2 cookies

Factory and return HTTP::Cookies object.

=cut

sub cookies {

	my $self = shift;

	my $agent_hash = shift
		or die __PACKAGE__ . "->cookies() missing argument";

	my $file = $self->{config}->{run_dir} . "/cookies/" . $agent_hash;

	my $now = time;

	if ( !utime( $now, $now, $file ) ) {

		open( FILE, ">>$file" );

		print FILE "#LWP-Cookies-1.0";

		close( FILE );
	}

	$cookie_jar = HTTP::Cookies->new(
			file => $file,
			autosave => 1,
		);

	return $cookie_jar;
}

=head2 any 

Creates and returns Lib::Agent::Instance object.

User agent data is selected randomly.

=cut

sub any {

	my $self = shift;

	my $named_parameters = shift;

	my $agent = $self->{agents}->[rand @{$self->{agents}}];

	if ( $named_parameters->{locale} ) {

		$agent->{headers}->{headers}->{'Accept-Language'} = $self->locale( $named_parameters->{locale} );
	}

	my $this_agent = Lib::Agent::Instance->new( $agent ) 
		or die __PACKAGE__ . "->get() Lib::Agent::Instance->new() failed";

	return bless( $this_agent, Lib::Agent::Instance );
}

=head2 get 

Creates and returns Lib::Agent::Instance object.

User agent data is selected by index.

=cut

sub get {

	my $self = shift;

	my $index = 0;

	if (@_) { $index = shift; }

	if ( $index < 0 || $index >= @{$self->{agents}} ) {

		die __PACKAGE__ . "->get() out of range";
	}

	my $named_parameters = shift;

	my $agent = $self->{agents}->[$index];

	if ( $named_parameters->{locale} ) {

		$agent{headers}->{headers}->{'Accept-Language'} = $self->locale( $named_parameters->{locale} );
	}

	my $this_agent = Lib::Agent::Instance->new( $agent ) 
		or die __PACKAGE__ . "->get() Lib::Agent::Instance->new() failed";

	return bless( $this_agent, Lib::Agent::Instance );
}

package Lib::Agent::Instance;

=pod

=head1 NAME

Lib::Agent::Instance - Class to hold user agent instance

=head1 SYNOPSIS

	use Lib::Agent::Instance;

	my $this_agent = Lib::Agent::Instance->new( \%agent );

	$this_agent->agent();		# returns user agent string

	$this_agent->headers();		# returns http headers hash

	$this_agent->cookie_jar();	# returns HTTP::Cookies object

=head1 DESCRIPTION

Class to hold user agent instance and to get user agent parameters.

=cut

sub new {

	my $class = shift;

	my $self = {};

	bless( $self, $class );

	$self->{this_agent} = shift
		or die __PACKAGE__ . "->new() missing argument";

	return $self;
}

=head1 METHODS

=head2 agent

Returns user agent string.

=cut

sub agent {

	my $self = shift;

	return $self->{this_agent}->{headers}->{agent};
}

=head2 headers 

Returns http headers hash.

=cut

sub headers {

	my $self = shift;

	return $self->{this_agent}->{headers}->{headers};
}

=head2 cookie_jar 

Returns HTTP::Cookies object.

=cut

sub cookie_jar {

	my $self = shift;

	return $self->{this_agent}->{cookie_jar};
}

=head2 reset_cookie_jar 

Delete cookie jar file.

=cut

sub clear_cookie_jar {

	my $self = shift;

	my $cookie_jar = $self->cookie_jar;

	$cookie_jar->clear();
}

=head2 referer

Get/set header referer entry.

=cut

sub referer {

	my $self = shift;

	my $headers = $self->headers;

	if ( my $referer = shift ) {

		$headers->{Referer} = $referer;
	}

	return $headers->{Referer};
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
