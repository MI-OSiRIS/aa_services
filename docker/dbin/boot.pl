#!/usr/bin/env perl

print "OSiRIS AA Docker Boot Loader\n";
print "(c) 2016 Wayne State University\n\n";

use POSIX qw(setuid setgid);
use BSD::Resource;

# figure out what we'll be exec-ing
my @args;
foreach my $arg (@ARGV) {
    if ($arg =~ /\s+/) {
        push(@args, "'$arg'");
    } else {
        push(@args, $arg);
    }
}
my $to_run = join(' ', @args);

if ($ENV{STAY_ROOT}) {
    if (-e $config_file) {
        print "[@{[$c->{front_door_host}]}] running: $to_run (as root)\n";
        system(@ARGV);
    } else {
        print "[error]: please configure aa_services using aa_services.conf before proceeding\n";
        exit 1;
    }
} else {
    # become oaasvc user
    my $run_as_uid = `id -u oaasvc`;
    my $run_as_gid = `id -g oaasvc`;
    chomp($run_as_uid, $run_as_gid);

    setgid($run_as_gid);
    setuid($run_as_uid);
}

sub db_exists {
    my ($db) = @_;
    if (`psql -d template1 -tAc "select 1 from pg_database where datname='$db'"` == 1) {
        return 1;
    }
    return undef;
}