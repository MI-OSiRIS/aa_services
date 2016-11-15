#!/usr/bin/env perl

#
# oakd and stpd may have their own id management commands, but I'm creating this
# tool as part of the development process to create and manage keys generically.
#

use OSiRIS::AccessAssertion::Certificate;
use OSiRIS::AccessAssertion::Key;
use OSiRIS::AccessAssertion::Util qw/gen_rsa_keys new_uuid/;
use OSiRIS::Config;
use POSIX 'strftime';
use File::Copy;

BEGIN { 
    unless ($ENV{AA_HOME}) {
        print "[debug] AA_HOME environment variable undefined, defaulting to /opt/osiris/aa_services\n" if $ENV{AA_DEBUG};
        $ENV{AA_HOME} = "/opt/osiris/aa_services";
    }
}

# load configuration file
my $config = OSiRIS::Config->parse("$ENV{AA_HOME}/etc/aa_services.conf");

use Getopt::Long qw(GetOptions :config no_auto_abbrev no_ignore_case);

my $command = shift @ARGV;

if ($command = "genkeys") {
    GetOptions(
        'd|key-directory' => \my $keys_directory,
        'f|force-new' => \my $force_new,
        'r|refresh-cert' => \my $refresh_cert,
        'g|gen-new-keys' => \my $gen_new_keys,
        'e|entity-id' => \my $entity_id,        
    );

    unless ($keys_directory) {
        $keys_directory = "$ENV{AA_HOME}/etc/keys";
    }

    my ($file_count, $link_count);
    foreach my $file (qw/sign.crt sign.key enc.crt enc.key/) {
        if (-l "$keys_directory/$file") {
            ++$link_count;
        } elsif (-f "$keys_directory/$file") {
            ++$file_count;
        }
    }

    if ($file_count) {
        if ($force_new) {
            foreach my $file (qw/sign.crt sign.key enc.crt enc.key/) {
                if (-e "$keys_directory/$file") {
                    move("$keys_directory/$file", "$keys_directory/$file.@{[time]}.bak");
                }
            }
        } else {
            die "[fatal] keys already exist, run with --force-new to force creation\n";
        }
    }
    my $cn = $entity_id ? $entity_id : 'urn:uid:' . new_uuid();
    my ($sc, $sk, $ec, $ek);
    if ($link_count == 4) {
        # signing pair
        $sc = OSiRIS::AccessAssertion::Certificate->new("$keys_directory/sign.crt");
        $sk = OSiRIS::AccessAssertion::Key->new({ cert => $sc, file => "$keys_directory/sign.key"});

        # crypto pair
        $ec = OSiRIS::AccessAssertion::Certificate->new("$keys_directory/enc.crt");
        $ek = OSiRIS::AccessAssertion::Key->new({ cert => $ec, file => "$keys_directory/enc.key"});

        my $time = time;
        if ($refresh_cert) {
            if ($gen_new_keys) {

            } else {
                self_sign_key($sc->config, "$keys_directory/sign.key", "$keys_directory/sign.@{[strftime('%F-%I.%M.%S.%p', localtime($time))]}.crt")
            }
        }
    }

    $cn = "urn:uuid:" . new_uuid();
}
