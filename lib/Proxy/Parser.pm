package Proxy::Parser;

=pod

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Switch;

use Data::Dumper;

use Lib::Result;

use Proxy::Parser::Astrill;

use Proxy::Parser::BNLGov;

use Proxy::Parser::Etes;

use Proxy::Parser::ExpressVPN;

use Proxy::Parser::FreeProxyLists;

use Proxy::Parser::HideMe;

use Proxy::Parser::IPLocation;

use Proxy::Parser::ShowIP;

use Proxy::Parser::SSLProxies;

sub new {

	my $class = shift;

	my $self = {};

	bless( $self, $class );

	$self->{verbose} = undef;

	$self->{config}	= shift
		or die __PACKAGE__ . "->new() missing config data";

	$self->{logging} = shift;

	$self->{named_parameters} = shift; 

	return $self;
}

=head1 ATTRIBUTES

=head2 verbose

=cut

sub verbose {

	my $self = shift;

	if ( @_ ) {

		$self->{verbose} = shift;
	}

	return $self->{verbose};
}

=head2 logging

=cut

sub logging {

	my $self = shift;

	if ( $self->{named_parameters}->{logging} && $self->{logging} ) {

		return $self->{logging};
	}

	return undef;
}

=head2 target

=cut

sub target {

	my $self = shift;

	if ( $self->{named_parameters}->{target} ) {

		$self->{target} = $self->{named_parameters}->{target};
	}

	return $self->{target};
}

=head2 type

=cut

sub type {

        my $self = shift;

        if ( $self->{named_parameters}->{type} ) {

		$self->{type} = $self->{named_parameters}->{type};
	}

        return $self->{type};
}

=head2 file

=cut

sub file {

        my $self = shift;

        if ( $self->{named_parameters}->{file} ) {

		$self->{file} = $self->{named_parameters}->{file};
	}

        return $self->{file};
}

=head2 use_filter

=cut

sub use_filter {

        my $self = shift;

        if ( $self->{named_parameters}->{filter} ) {

		$self->{filter} = $self->{named_parameters}->{filter};
	}

        return $self->{filter};
}

=head1 METHODS

=head2 keys 

=cut

sub keys {

	my $self = shift;

	if ( $self->type ) {

		if ( $self->{type} eq qw(check) ) {

			return ( 'ip' );
		}

		if ( $self->{type} eq qw(explore) ) {

			return ( 'uri', 'seed' );
		}

		if ( $self->{type} eq qw(scrape) ) {

			return ( 'ip', 'port', 'seed' );
		}
	}
	die __PACKAGE__ . "->keys() unknown parser type. Use " . __PACKAGE__ . "->type() to set or get parser type";
}

=head2 module

=cut

sub module {

	my $self = shift;

	my $mod = __PACKAGE__ . "::";

	switch ( $self->target ) {

		case /^astrill/		{ $mod .= 'Astrill'; }

		case /^bnl/		{ $mod .= 'BNLGov'; }

		case /^etes/		{ $mod .= 'Etes'; }

		case /^expressvpn/	{ $mod .= 'ExpressVPN'; }

		case /^freeproxylists/	{ $mod .= 'FreeProxyLists'; }

		case /^hide/		{ $mod .= 'HideMe'; }

		case /^iplocation/	{ $mod .= 'IPLocation'; }

		case /^showip/		{ $mod .= 'ShowIP'; }

		case /^sslproxies/	{ $mod .= 'SSLProxies'; }

		else 			{ die __PACKAGE__ . "->module() parser module not implemented"; }
	}

	return $mod;
}

=head2 parse 

=cut

sub parse {

	my $self = shift;

	if ( $self->logging ) {

		$self->{logging}->entry( 2, "Parsing " . $self->target . " response data ..." );
	}

	if ( $self->type ) {

		my $result = Lib::Result->new()
			or die __PACKAGE__ . "->parse() Lib::Result->new() failed";

		my $mod = $self->module();

		my $parser = $mod->new( $self->{config}, $self->{named_parameters} );

		if ( $self->{type} eq qw(check) ) {

			$parser->check( $result, \$self->{data} );
		}

		if ( $self->{type} eq qw(explore) ) {

			$parser->explore( $result, \$self->{data} );
		}

		if ( $self->{type} eq qw(scrape) ) {

			$parser->use_filter( $self->use_filter );

			$parser->scrape( $result, \$self->{data} );
		}

		if ( $self->logging ) {

			$self->{logging}->entry( 2, "... done" );
		}

		return bless( $result, Lib::Result );
	}
	die __PACKAGE__ . "->parse() unknown parser type. Use " . __PACKAGE__ . "->type() to set or get parser type";
}

=head2 print 

=cut

sub print {

	my $self = shift;

	my $ref = shift or die __PACKAGE__ . "->print() missing argument";

	if ( ref $ref eq 'ARRAY' ) {

		foreach my $item ( @$ref ) {

			foreach my $key ( $self->keys() ) {

				if ( defined( $item->{$key} ) ) {

					printf( "%-16s => %-32s\n", $key, $item->{$key} );
				}
			}
		}
	}
	elsif ( ref $ref eq 'HASH' ) {

		foreach my $key ( $self->keys() ) {

			if ( defined( $ref->{$key} ) ) {

				printf( "%-16s => %-32s\n", $key, $ref->{$key} );
			}
		}
	}
}

=head2 run 

=cut

sub run {

	my $self = shift;

	my $data = undef;

	if ( $self->file ) {

		if ( -e $self->{file} ) {

			$data = '';

			open( IN, "<", $self->{file} );

			while ( defined( $line = <IN> ) ) {

				$data .= $line;
			}

			close( IN );
		}
		else {
			die __PACKAGE__ . "->run() file " . $self->{file} . " not found";
		}
	}
	else {
		$data = shift
			or die __PACKAGE__ . "->run() missing argument";
	}

	$self->{data} = $data;

	return $self->parse();
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
