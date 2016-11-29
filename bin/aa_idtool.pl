#!/usr/bin/env perl

#
# oakd and stpd may have their own id management commands, but I'm creating this
# tool as part of the development process to create and manage keys generically.
#

use OSiRIS::AccessAssertion::Certificate;
use OSiRIS::AccessAssertion::Key;
use OSiRIS::AccessAssertion::Util qw/gen_rsa_keys new_uuid self_sign_key/;
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

# dispatch to subcommand...
eval {
    &{"main::c_$command"}()
};

if ($@ =~ /^\QUndefined subroutine &main::c_\E/) {
    die usage();
} elsif ($@) {
    die $@;
}

sub c_genkeys {
    GetOptions(
        'd|key-directory' => \my $keys_directory,
        'r|refresh-cert' => \my $refresh_cert,
        'g|gen-new-keys' => \my $gen_new_keys,
        'e|entity-id=s' => \my $entity_id,
        'h|help' => \my $help,        
    );

    die c_genkeys_usage() if $help;

    if ($force_new + $refresh_cert + $gen_kew_keys > 1) {
        die c_genkeys_usage();
    }

    unless ($keys_directory) {
        $keys_directory = "$ENV{AA_HOME}/etc/keys";
    }

    my ($file_count, $link_count);
    foreach my $file (qw/sign.crt sign.key enc.crt enc.key/) {
        if (-l "$keys_directory/$file") {
            ++$link_count;
        } elsif (-f "$keys_directory/$file") {
            die "[fatal] $keys_directory/$file is not a symlink!\n";
        }
    }

    my $file_time = strftime('%F-%I.%M.%S.%p', localtime());
    my ($sc, $sk, $ec, $ek);
    if ($link_count == 4) {
        # signing pair
        $sc = OSiRIS::AccessAssertion::Certificate->new("$keys_directory/sign.crt");
        $sk = OSiRIS::AccessAssertion::Key->new({ cert => $sc, file => "$keys_directory/sign.key"});

        # crypto pair
        $ec = OSiRIS::AccessAssertion::Certificate->new("$keys_directory/enc.crt");
        $ek = OSiRIS::AccessAssertion::Key->new({ cert => $ec, file => "$keys_directory/enc.key"});

        if ($refresh_cert) {
            self_sign_key(
                $sc->config(force => 1), 
                "$keys_directory/sign.key", 
                "$keys_directory/sign.$file_time.crt",
            );
            system("rm", "$keys_directory/sign.crt");
            system("ln", '-s', "$keys_directory/sign.$file_time.crt", "$keys_directory/sign.crt");

            self_sign_key(
                $ec->config(force => 1), 
                "$keys_directory/enc.key", 
                "$keys_directory/enc.$file_time.crt",
            );
            system("rm", "$keys_directory/enc.crt");
            system("ln", '-s', "$keys_directory/enc.$file_time.crt", "$keys_directory/enc.crt");
            print "[info] new certificate generated for @{[$sc->common_name]} (@{[$sc->thumbprint]})\n";
        } elsif ($gen_new_keys) {
            my $key_config = $sc->config(force => 1);
            if ($entity_id) {
                $key_config->{common_name} = $entity_id;
            }
            gen_rsa_keys(
                $key_config,
                "$keys_directory/sign.$file_time.key",
                "$keys_directory/sign.$file_time.crt",
            );
            system("rm", "$keys_directory/sign.crt");
            system("rm", "$keys_directory/sign.key");
            system("ln", '-s', "$keys_directory/sign.$file_time.crt", "$keys_directory/sign.crt");                
            system("ln", '-s', "$keys_directory/sign.$file_time.key", "$keys_directory/sign.key");

            $key_config->{type} = "enc";
            gen_rsa_keys(
                $key_config,
                "$keys_directory/enc.$file_time.key",
                "$keys_directory/enc.$file_time.crt",
            );
            system("rm", "$keys_directory/enc.crt");
            system("rm", "$keys_directory/enc.key");
            system("ln", '-s', "$keys_directory/enc.$file_time.crt", "$keys_directory/enc.crt");                
            system("ln", '-s', "$keys_directory/enc.$file_time.key", "$keys_directory/enc.key");

            $sc = OSiRIS::AccessAssertion::Certificate->new("$keys_directory/sign.crt");
            print "[info] new private keys and certificates generated for @{[$sc->common_name]} (@{[$sc->thumbprint]})\n";
        } else {
            print "[info] keys exist for @{[$sc->common_name]} (@{[$sc->thumbprint]})\n";
            print "       specify --gen-new-keys or --refresh-cert to update existing keys\n";
            exit();
        }
    } else {
        # config for the signing key first.
        my $key_config = {
            common_name => $entity_id ? $entity_id : "urn:uuid:@{[new_uuid()]}",
            type => "sign",
        };
        foreach my $opt (qw/ country state locality organization organizational_unit email_address /) {
           if (exists $config->{$opt} && $config->{$opt}) {
               $key_config->{$opt} = $config->{$opt};
           }
        }

        if (exists $config->{rsa_key_size} && $config->{rsa_key_size}) {
           $key_config->{bits} = $config->{rsa_key_size};
        }

        if (exists $config->{rsa_cert_validity} && $config->{rsa_cert_validity}) {
           $key_config->{days} = $config->{rsa_cert_validity};
        }

        gen_rsa_keys(
            $key_config,
            "$keys_directory/sign.$file_time.key",
            "$keys_directory/sign.$file_time.crt",
        );
        system("ln", '-s', "$keys_directory/sign.$file_time.crt", "$keys_directory/sign.crt");                
        system("ln", '-s', "$keys_directory/sign.$file_time.key", "$keys_directory/sign.key");

        # now make the encryption key, everything can be the same except the type
        $key_config->{type} = "enc";
        gen_rsa_keys(
            $key_config,
            "$keys_directory/enc.$file_time.key",
            "$keys_directory/enc.$file_time.crt",
        );
        system("ln", '-s', "$keys_directory/enc.$file_time.crt", "$keys_directory/enc.crt");                
        system("ln", '-s', "$keys_directory/enc.$file_time.key", "$keys_directory/enc.key");

        # grab this so we can print the thumbprint
        $sc = OSiRIS::AccessAssertion::Certificate->new("$keys_directory/sign.crt");
        print "[info] new private keys and certificates generated for @{[$sc->common_name]} (@{[$sc->thumbprint]})\n";
    }
}

sub c_genkeys_usage {
    return <<"EOF";

Usage: $0 genkeys [OPTIONS]

These options are available for 'genkeys':
    -d, --key-directory     Store / look for keys in this directory instead of the 
                            default location ($ENV{AA_HOME}/etc/keys)
    -e, --entity-id         Hard specifiy the entity_id to use, do not automatically
                            generate a UUID-based commonName for this key pair
    -h, --help              Show usage information

One of these parameters may also be specified:
    -r, --refresh-cert      Refresh the existing self signed certificate using the 
                            configuration of the existing certificate
    -g, --gen-new-keys      Generate a new private key and sign it using the
                            configuration of the existing certificate

EOF
}

sub usage {
    return <<"EOF";
Usage: $0 [SUBCOMMAND]

These subcomands are available for '$0':
    genkeys                 Generate, sign, or refresh certificates for keys

EOF
}