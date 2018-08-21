package Explorer::Parser;

=pod

=head1 NAME

Explorer::Parser

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Switch;

use Data::Dumper;

use Encode qw(encode);

use Lib::Result;

use Explorer::Parser::Bergfuerst;

use Explorer::Parser::Companisto;

use Explorer::Parser::DeutscheMikroinvest;

use Explorer::Parser::Exporo;

use Explorer::Parser::Indiegogo;

use Explorer::Parser::Kapilendo;

use Explorer::Parser::Kickstarter;

use Explorer::Parser::Seedmatch;

use Explorer::Parser::Startnext;

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

=head1 METHODS

=head2 module

=cut

sub module {

	my $self = shift;

	my $mod = __PACKAGE__ . "::";

	switch ( $self->target ) {

		case /^bergfuerst/	{ $mod .= 'Bergfuerst'; }

		case /^companisto/	{ $mod .= 'Companisto'; }

		case /^deutsche/	{ $mod .= 'DeutscheMikroinvest'; }

		case /^exporo/		{ $mod .= 'Exporo'; }

		case /^indiegogo/	{ $mod .= 'Indiegogo'; }

		case /^kapilendo/	{ $mod .= 'Kapilendo'; }

		case /^kickstarter/	{ $mod .= 'Kickstarter'; }

		case /^seedmatch/	{ $mod .= 'Seedmatch'; }

		case /^startnext/	{ $mod .= 'Startnext'; }

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

		my $parser = $mod->new( $self->{config}, $self->{logging}, $self->{named_parameters} );

		if ( $self->{type} eq qw(explore) ) {

			$parser->explore( $result, $self->{data} );
		}
		else {
			die __PACKAGE__ . "->parse() unknown or wrong parser type";
		}

		if ( $self->logging ) {

			$self->{logging}->entry( 2, "... done" );
		}

		return bless( $result, Lib::Result );
	}

	die __PACKAGE__ . "->parse() unknown or undefined parser type";
}

=head2 print 

=cut

sub print {

	my $self = shift;

	my $ref = shift or die __PACKAGE__ . "->print() missing argument";

	if ( ref $ref eq 'ARRAY' ) {

		foreach my $item ( @$ref ) {

			foreach my $key ( keys( %$item ) ) {

				printf( "%-16s => %-32s\n", $key, encode( 'UTf-8', $item->{$key} ) );
			}
		}
	}
	elsif ( ref $ref eq 'HASH' ) {

		foreach my $key ( keys( %$ref ) ) {

			printf( "%-16s => %-32s\n", $key, encode( 'UTF-8', $ref->{$key} ) );
		}
	}
}

=head2 run 

=cut

sub run {

	my $self = shift;

	$self->{data} = undef;

	if ( $self->file ) {

		if ( -e $self->{file} ) {

			$self->{data} = '';

			open( IN, "< :encoding(UTF-8)", $self->{file} );

			while ( defined( $line = <IN> ) ) {

				$self->{data} .= $line;
			}

			close( IN );
		}
		else {
			die __PACKAGE__ . "->run() file " . $self->{file} . " not found";
		}
	}
	else {
		$self->{data} = shift
			or die __PACKAGE__ . "->run() missing argument";
	}

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
