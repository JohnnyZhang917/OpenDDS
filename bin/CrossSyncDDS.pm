package CrossSyncDDS;

use CrossSync;

use Sys::Hostname;

@ISA = ("CrossSync"); #inherits from CrossSync

sub new {
    my $proto = shift;
    my $class = ref ($proto) || $proto;

    my ($verbose, $server_port, $client_port
	, $pub_ini, $sub_ini, $schedule_file) = @_;

    $verbose ||= 0;
    $pub_ini ||= "pub.ini";
    $sub_ini ||= "sub.ini";

    my $self =  $class->allocate ($verbose, $client_port
				  , $server_port, $schedule_file);

    if ($self) {
	$self->{PUB_INI} = $pub_ini;
	$self->{SUB_INI} = $sub_ini;

	if (!$self->_init ()) {
	    return $self;
	}
    }
}

sub get_config_info {
    my $self = shift;

    return ($self->{PUB_INI_TMP}, $self->{SUB_INI_TMP});
}

sub _init {
    my $self = shift;

    if ($self->_parse_schedule () == 0) {
	return $self->_create_custom_config ();
    }
}

sub _create_custom_config {
    my $self = shift;
    $self->{PUB_INI_TMP} = $self->{PUB_INI};
    $self->{SUB_INI_TMP} = $self->{SUB_INI};
    my $pid = getpgrp(0);
    my $verbose = $self->{VERBOSE};

    $self->{PUB_INI_TMP} = "pub$pid.ini";
    $self->{SUB_INI_TMP} = "sub$pid.ini";
    my $my_name = hostname();
    my $in_fh = new FileHandle();
    my $out_fh = new FileHandle();

    if (!open ($in_fh, "$self->{PUB_INI}")) {
	if ($verbose) {
	    print STDERR "Unable to open file \""
		. $self->{PUB_INI}. "\"\n";
	    return -1;
	}
    }
    if (!open ($out_fh, ">$self->{PUB_INI_TMP}")) {
	if ($verbose) {
	    print STDERR "Unable to open file \""
		. $self->{PUB_INI_TMP}. "\"\n";
	    close ($in_fh);
	    return -1;
	}
    }
    while(<$in_fh>) {
	$_ =~ s/localhost/$my_name/g;
	print $out_fh $_;
    }
    close ($out_fh);
    close ($in_fh);

    if (!open ($in_fh, "$self->{SUB_INI}")) {
	if ($verbose) {
	    print STDERR "Unable to open file \""
		. $self->{SUB_INI}. "\"\n";
	    return -1;
	}
    }
    if (!open ($out_fh, ">$self->{SUB_INI_TMP}")) {
	if ($verbose) {
	    print STDERR "Unable to open file \""
		. $self->{SUB_INI_TMP}. "\"\n";
	    close ($in_fh);
	    return -1;
	}
    }
    while(<$in_fh>) {
	$_ =~ s/localhost/$my_name/g;
	print $out_fh $_;
    }
    close ($out_fh);
    close ($in_fh);

    return 0;
}
