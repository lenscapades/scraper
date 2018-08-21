package Json_Api::Socket;

=pod

=head1 NAME

Json_Api::Socket - class to manage server socket

=head1 SYNOPSIS

	use Json_Api::Socket;

	my $json_api = Json_Api::Socket->new( ... );

	$json_api->run()

=head1 DESCRIPTION

=cut

use Json_Api::Request;

use IO::Socket::UNIX;

use POSIX qw( :sys_wait_h );

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

	$self->{socket_name} = $self->{config}->{tmp_dir} . "/json_api_socket";

	$self->{request} = Json_Api::Request->new(

				$self->{config},

				$self->{logging},

				$self->{info},
			
			) or die __PACKAGE__ . "->new() Json_Api::Request->new() failed";

	return $self;
}

=head1 METHODS

=cut
 
sub run {

	my $self = shift;

	my $socket = $self->get_socket();

	while (1) {

		$self->service_clients( $socket );
	}

	close( $socket );
}

sub get_socket {

	my $self = shift;

	unlink( $self->{socket_name} );

	my $socket = IO::Socket::UNIX->new(

		Local => $self->{socket_name},
		Type => SOCK_STREAM,
		Listen => 5,
	)
	or die "Cannot create socket $!\n";

	return $socket;
}

sub service_clients { 

	my $self = shift;

	my $socket = shift;

	$SIG{CHLD} = sub { $self->reaper };
    
	my $client;

	while ( $client = $socket->accept() ) {

		my $pid = fork();

		die "Cannot fork\n" unless defined $pid;

		if ( $pid ) {

			close $client;

			next;
		}

		close $socket;

		$self->process_requests( $client );

		exit;
	}
}

sub process_requests {

	my $self = shift;

	my $client = shift;

	$0 = "unixsockd: handling requests...";  

	while ( my $line = <$client> ) {

		last if $line =~ /^\s$/;

        	chomp $line;

		# put some more useful code here to read each line or whatever...

		$line = $self->{request}->run( $line );

		printf $client "%s\n", $line;

                # return something to client
    }
}

sub reaper { 

	my $self = shift;

	while ( waitpid( -1, WNOHANG ) > 0 ) {}
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
