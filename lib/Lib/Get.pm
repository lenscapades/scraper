package Lib::Get;

=pod

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

=head1 CONSTRUCTOR

=cut

use Data::Dumper;

use Encode qw(encode);

use Encode::Guess;

use IO::Socket::SSL;

use LWP::UserAgent;

use Lib::Datetime;

use Lib::Result;

use Lib::Agent;

use Proxy::Parser;

use Explorer::Parser;

use Scraper::Parser;

sub new {

	my $class = shift;

	my $self = {};

	bless( $self, $class );

	$self->{config}	= shift
		or die __PACKAGE__ . "->new() missing config data";

	$self->{logging} = shift;

	$self->{named_parameters} = shift;

	$self->verbose( $self->{named_parameters}->{verbose} );

	return $self;
}


=head1 ATTRIBUTES

=head2 verbose

Do not be quiet.

=cut

sub verbose {

	my $self = shift;

	if ( my $verbose = shift ) {

		$self->{verbose} = $verbose;
	}

	return $self->{verbose};
}

sub logging {

	my $self = shift;

        if ( $self->{named_parameters}->{logging} && $self->{logging} ) {

		return $self->{logging};
	}

	return undef;
}

=head2 daemon

=cut

sub daemon {

        my $self = shift;

        if ( $self->{named_parameters}->{daemon} ) {

		$self->{daemon} = $self->{named_parameters}->{daemon};
	}

        return $self->{daemon};
}

=head2 has_agent

=cut

sub has_agent {

        my $self = shift;

        if ( $self->{named_parameters}->{agent} ) {

		$self->{agent} = $self->{named_parameters}->{agent};
	}

        return $self->{agent};
}

=head2 has_proxy

=cut

sub has_proxy {

        my $self = shift;

        if ( $self->{named_parameters}->{proxy} ) {

		$self->{proxy} = $self->{named_parameters}->{proxy};
	}

        return $self->{proxy};
}

=head1 METHODS

=head2 autosave

=cut

sub autosave {

	my $self = shift;

	if ( $self->{named_parameters_methods}->{autosave} ) {

		$self->{autosave} = $self->{named_parameters_methods}->{autosave};
	}

	return $self->{autosave};
}

=head2 locale

=cut

sub locale {

	my $self = shift;

	if ( $self->{named_parameters_methods}->{locale} ) {

		$self->{locale} = $self->{named_parameters_methods}->{locale};
	}

	return $self->{locale};
}

=head2 page_number

=cut

sub page_number {

	my $self = shift;

	if ( defined( $self->{named_parameters_methods}->{page_number} ) ) {

		$self->{page_number} = $self->{named_parameters_methods}->{page_number};
	}

	return $self->{page_number};
}

=head2 target

=cut

sub target {

	my $self = shift;

	if ( $self->{named_parameters_methods}->{target} ) {

		$self->{target} = $self->{named_parameters_methods}->{target};
	}

	return $self->{target};
}

=head2 proxy

=cut

sub proxy {

	my $self = shift;

	if ( $self->{named_parameters_methods}->{proxy} ) {

		$self->{proxy} = $self->{named_parameters_methods}->{proxy};
	}

	return $self->{proxy};
}

=head2 referer

=cut

sub referer {

        my $self = shift;

        if ( $self->{named_parameters_methods}->{referer} ) {

		$self->{referer} = $self->{named_parameters_methods}->{referer};
	}

        return $self->{referer};
}

=head2 request

=cut

sub request {

        my $self = shift;

        if ( $self->{named_parameters_methods}->{request} ) {

		$self->{request} = $self->{named_parameters_methods}->{request};
	}

        return $self->{request};
}

=head2 time_zone

=cut

sub time_zone {

        my $self = shift;

        if ( $self->{named_parameters_methods}->{time_zone} ) {

		$self->{time_zone} = $self->{named_parameters_methods}->{time_zone};
	}

        return $self->{time_zone};
}

=head2 type

=cut

sub type {

        my $self = shift;

        if ( $self->{named_parameters_methods}->{type} ) {

		$self->{type} = $self->{named_parameters_methods}->{type};
	}

        return $self->{type};
}

=head2 client 

=cut

sub client {

	my $self = shift;

	$self->{client} = LWP::UserAgent->new(
		ssl_opts => {
			SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE,
			verify_hostname => 0,
		} )
		or die __PACKAGE__ . "->client() LWP::UserAgent->new() failed";

	if ( $self->has_proxy ) {

		$self->{client}->proxy( 'https', 'connect://' . $self->proxy . '/' );

		if ( $self->logging ) {

			$self->{logging}->entry( 2, "Using proxy " . $self->proxy );
		}
	}

	if ( $self->has_agent ) { 

		$self->{agent} = Lib::Agent->new(
				$self->{config}
			)
			or die __PACKAGE__ . "->client() Lib::Agent->new() failed";

		$self->{this_agent} = $self->{agent}->any( locale => $self->locale );

		if ( $self->logging ) {

			$self->{logging}->entry( 2, "Using agent " . $self->{this_agent}->agent );
		}

		$self->{client}->agent( $self->{this_agent}->agent );

		$self->{client}->cookie_jar( $self->{this_agent}->cookie_jar );
	}

	return $self->{client};
}

=head2 get_request

=cut

sub get_request {

	my $self = shift;

	if ( my $request = $self->request ) {

		my $page_number = $self->page_number;

		if ( defined( $page_number ) ) {

			if ( $page_number >= 0 && $request =~ /(\$page=\d)/ ) {

				$request =~ s/\$page=\d/$page_number/;

				return $request;
			}
		}

		return $request;
	}

	return undef;
}

=head2 set_referer

=cut

sub set_referer {

	my $self = shift;

	if ( my $referer = $self->referer ) {

		if ( $self->logging ) {

			$self->{logging}->entry( 2, "Using referer " . $referer );
		}

		$self->{this_agent}->referer( $referer );
	}
}

=head2 get_headers

=cut

sub get_headers {

	my $self = shift;

	my @headers = $self->{this_agent}->headers();

	return @headers;
}

=head2 delay

=cut

sub delay {

	my $self = shift;

	if ( $self->{config}->{request_max_delay} ) {

		my $delay = $self->{config}->{request_min_delay}
			+ int rand ( $self->{config}->{request_max_delay} 
				- $self->{config}->{request_min_delay} + 1 );

		if ( $self->logging ) {

			$self->{logging}->entry( 2, "Delaying request for $delay seconds" );
		}

		sleep( $delay );
	}
}

=head2 get_response

=cut

sub get_response {

	my $self = shift;

	$self->{named_parameters_methods} = shift
                or die __PACKAGE__ . "->get_response() missing argument";

	$self->client();

	my $uri = $self->get_request();

	$self->set_referer();

	$self->delay();

	my $result = new Lib::Result
                or die __PACKAGE__ . "->get_response() Lib::Result->new() failed";
	
	if ( $self->logging ) {

		$self->{logging}->entry( 2, "Sending request $uri" );
	}

	my $req = HTTP::Request->new( 'GET', $uri );

	$req->header( $self->get_headers );

	my $response = $self->{client}->request( $req );

	if ( $self->logging ) {

		$self->{logging}->entry( 2, "Received response " . $response->status_line );
	}

	if ( $response->is_success ) { 

		$result->message( $response->status_line );

		if ( $response->decoded_content ) {

			my $decoded_content = $self->decode_content( $response->decoded_content );

			if ( $decoded_content ) {

				$result->content( $decoded_content );

				if ( $self->autosave ) {

					$self->do_autosave( $decoded_content );
				}
			}
			else {
				$result->error(1);

				$result->message( "500 Unknown error" );
			}
		}
		else {
			$result->error(1);

			$result->message( "500 Unknown error" );
		}
	}
	else {
		$result->error(1);

		$result->message( $response->status_line );

		if ( $response->status_line =~ /^404/ ) {

			my $decoded_content = $self->decode_content( $response->decoded_content );

			if ( $decoded_content ) {

				$result->content( $decoded_content );

				if ( $self->autosave ) {

					$self->do_autosave( $decoded_content );
				}
			}
		}
	}

	return bless( $result, Lib::Result );
}

=head2 do_autosave

=cut

sub do_autosave {

	my $self = shift;

	my $content = shift
		or die __PACKAGE__ . "->do_autosave() missing argument";

	my $datetime = new Lib::Datetime( $self->{config} )
		or die __PACKAGE__ . "->new() Lib::Datetime->new() failed";

	my $now = $datetime->long();

	$now =~ s/ /T/;

	my $file = $self->{config}->{tmp_dir} . '/'
			. $self->target . '.'
			. $self->type . '.'
			. $now . '.data';

	open( OUT, "> :encoding(UTF-8)", $file );

	print OUT $content;

	close( OUT );
}

=head2 decode_content

=cut

sub decode_content {

	my $self = shift;

	my $content = shift
		or die __PACKAGE__ . "->decode_content() missing argument";

	my $decoder = Encode::Guess->guess( $content );

	my $class = ref $decoder;

	if ( $self->{logging} ) {

		$self->{logging}->entry( 3, "Using content decoder $class" );
	}

	if ( $class eq 'Encode::utf8' ) {

		return $content;
	}
	else {
  	        return encode( 'UTF-8', $decoder->decode( $content ) );
	}
}

sub validate_not_found {

	my $self = shift;

	$self->parser();

	my $response = shift
		or die __PACKAGE__ . "->get_content() missing argument";

	my $result = $self->{parser}->validate_not_found( $response );

	if ( !$result->error ) {

		return 1;
	}

	return 0;
}

=head2 get_content

=cut

sub get_content {

	my $self = shift;

	$self->parser();

	my $response = shift
		or die __PACKAGE__ . "->get_content() missing argument";

	my $result = $self->{parser}->run( $response );

	if ( $result->error ) {

		if ( $self->has_agent ) {

			$self->{this_agent}->clear_cookie_jar();
		}
	}

	return bless( $result, Lib::Result );
}

=head2 module 

=cut

sub module {

	my $self = shift;

	my $mod = ucfirst( lc( $self->daemon ) ) . "::Parser";

	return $mod;
}

=head2 parser 

=cut

sub parser {

	my $self = shift;

	if ( !defined( $self->{parser} ) ) {

		my $mod = $self->module();

		$self->{parser} = $mod->new(

					$self->{config},

					$self->{logging},

					$self->{named_parameters_methods}

			) or die __PACKAGE__ . "->parser() $mod->new() failed";
	}

	return $self->{parser};
}

sub print {

	my $self = shift;

	my $content_ref = shift
		or die __PACKAGE__ . "->print() missing argument";

	if ( ref $content_ref eq "ARRAY" ) {
	
		foreach $item ( @$content_ref ) {

			foreach $key ( keys( %$item ) ) {

				printf( "%-24s => %-32s\n",  $key, encode( 'UTF-8', $item->{$key} ) );
			}
		}
	}
	elsif ( ref $content_ref eq "HASH" ) {

		foreach $key ( keys( %$content_ref ) ) {

			printf( "%-24s => %-32s\n",  $key, encode( 'UTF-8', $content_ref->{$key} ) );
		}
	}
	else {

		die __PACKAGE__ . "->print() there is always more than one way to fuck up";
	}
}

1;
