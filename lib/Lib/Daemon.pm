package Lib::Daemon;

sub new {

	my $class = shift;

	my $self = {};

	bless($self, $class);

	$self->{name} = shift
		or die __PACKAGE__ . "->new() missing process name"; 

	$self->{term} = 0;

	$self->{process} = undef;

	return $self;
}

sub run {

	my $self = shift;

	$self->{process} = shift
		or die __PACKAGE__ . "->run() missing process reference"; 

	my $process = ${$self->{process}};

	use POSIX qw(setsid);

	chdir '/';

	umask 0;

	open STDIN, '/dev/null' or die "Can not read /dev/null: $!";

	if ( !$process->verbose ) {

		open STDOUT, '>>/dev/null' or die "Can not write to /dev/null: $!";

		open STDERR, '>>/dev/null' or die "Can not write to /dev/null: $!";
	}

	defined(my $pid = fork) 
		or die __PACKAGE__ . "->run() can not fork";

	exit if $pid;

	POSIX::setsid() 
		or die __PACKAGE__ . "->run() can not start a new session";

	$pid = $process->{info}->set_pid($$);

	$process->{logging}->entry( 1, $self->{name} . " daemon (pid $pid) started." );

	$SIG{INT} = $SIG{TERM} = $SIG{HUP} = $SIG{KILL} = sub { $self->signal_handler };
	$SIG{PIPE} = 'ignore';

	until ($self->{term}) {

		$process->run();
	}

	$process->clear();

	$pid = $process->{info}->delete_pid();

	$process->{logging}->entry( 1, $self->{name} . " daemon (pid $pid) terminated." );
}

sub signal_handler {

	my $self = shift;

	$self->{term} = 1;
}

1;
