#!/usr/bin/env perl

#
# oakd and stpd may have their own id management commands, but I'm creating this
# tool as part of the development process to create and manage keys generically.
#

use OSiRIS::AccessAssertion::RSA::Certificate 'harness';
use OSiRIS::AccessAssertion::RSA::Key;
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

#
# Subcommand: keyinfo
#

sub c_keyinfo {
    GetOptions(
        'd|key-directory' => \my $keys_directory,
        'v|verbose' => \my $verbose,
        'e|export-pem' => \my $export_pem,
        'j|export-jwk' => \my $export_jwk,
        's|export-secret-keys' => \my $export_secret_keys,
        'h|help' => \my $help,
    );

    if ($help) {
        print c_keyinfo_usage();
        exit();
    }

    unless ($keys_directory) {
        $keys_directory = "$ENV{AA_HOME}/etc/keys";
    }

    if (   
      -e "$keys_directory/sign.crt" &&
      -e "$keys_directory/sign.key" &&
      -e "$keys_directory/enc.crt" &&
      -e "$keys_directory/enc.key") {
      
        if ($verbose) {
            if (-l "$keys_directory/sign.crt") {
                print "[info] loading signing certificate from $keys_directory/sign.crt\n";
                print "       sign.crt is a link to " . readlink("$keys_directory/sign.crt") . "\n";
            }

            if (-l "$keys_directory/sign.key") {
                print "[info] loading signing secret key from $keys_directory/sign.key\n";
                print "       sign.key is a link to " . readlink("$keys_directory/sign.key") . "\n";
            }

            if (-l "$keys_directory/enc.crt") {
                print "[info] loading encryption certificate from $keys_directory/enc.crt\n";
                print "       sign.crt is a link to " . readlink("$keys_directory/enc.crt") . "\n";
            }

            if (-l "$keys_directory/sign.key") {
                print "[info] loading encryption secret key from $keys_directory/enc.key\n";
                print "       sign.key is a link to " . readlink("$keys_directory/enc.key") . "\n";
            }
        }

        # signing pair
        my $sc = OSiRIS::AccessAssertion::RSA::Certificate->new("$keys_directory/sign.crt");
        my $sk = OSiRIS::AccessAssertion::RSA::Key->new({ cert => $sc, file => "$keys_directory/sign.key"});

        # crypto pair
        my $ec = OSiRIS::AccessAssertion::RSA::Certificate->new("$keys_directory/enc.crt");
        my $ek = OSiRIS::AccessAssertion::RSA::Key->new({ cert => $ec, file => "$keys_directory/enc.key"});

        print "\nKey Information\n";
        print "-----------------------------------------------------------------\n";
        if ($sc->common_name eq $ec->common_name) {
            print "Entity ID         : " . $sc->common_name . "\n";
        } else {
            die "CN of signing and encryption certificates differs.  Bad keypair!\n";
        }
        print "JWK Thumbprint    : " . $sc->thumbprint . "\n";
        
        foreach my $namepart (qw/org ou email locality state country/) {
            my $method = "subject_$namepart";
            my $label = ucfirst($namepart) . (" " x (18 - length($namepart))) . ": ";
            print $label . $sc->$method . "\n";;
        }
        
        if (scalar(@{$sc->SubjectAltName})) {
            my @sans = map { s/dNSName=/DNS:/g && $_ } @{$sc->SubjectAltName};
            print "Subject Alt Names : $sans[0]\n";
            foreach my $san (@sans[1..$#sans]) {
                print " " x 18 . ": $san\n";
            }
        }

        print "Valid Until (sig) : " . scalar localtime($sc->not_after) . "\n";
        print "Valid Until (enc) : " . scalar localtime($ec->not_after) . "\n";
        print "\n";

        if ($export_jwk) {
            print "JWK Export\n";
            print "-----------------------------------------------------------------\n";
            print "[signing public jwk]\n";
            print $sc->pubkey->export_key_jwk('public');
            print "\n\n[encryption public jwk]\n";
            print $ec->pubkey->export_key_jwk('public');
            if ($export_secret_keys) {
                print "\n\n[signing secret jwk]\n";
                print $sk->export_key_jwk('private');
                print "\ n\n[encryption secret jwk]\n";
                print $ek->export_key_jwk('private');
            }
            print "\n\n";
        }

        if ($export_pem) {
            print "PEM Export\n";
            print "-----------------------------------------------------------------\n";
            print "[signing certificate]\n";
            print $sc->to_pem;
            print "\n\n[encryption certificate]\n";
            print $ec->to_pem;
            print "\n\n[signing public key]\n";
            print $sc->pubkey->export_key_pem('public');
            print "\n\n[encryption public key]\n";
            print $ec->pubkey->export_key_pem('public');
            if ($export_secret_keys) {
                print "\n\n[signing secret key]\n";
                print $sk->export_key_pem('private');
                print "\n\n[encryption secret key]\n";
                print $ek->export_key_pem('private');
            }
            print "\n\n";
        }
    } else {
        print "[info] signing and encryption keys not found in '$keys_directory'\n";
    }
}

sub c_keyinfo_usage {
    return <<"EOF";

Usage: $0 keyinfo [OPTIONS]

These options are available for 'keyinfo':
    -d, --key-directory      Store / look for keys in this directory instead of the 
                             default location ($ENV{AA_HOME}/etc/keys)
    -e, --export-pem         Print certificates and public keys to STDOUT in PEM 
                             format
    -j, --export-jwk         Print public keys to STDOUT in JWK format
    -s, --export-secret-keys Also include secret keys when using the -e or -j options
    -h, --help               Show usage information
    -v, --verbose            Print extra information

EOF
}

sub usage {
    return <<"EOF";
Usage: $0 [SUBCOMMAND]

These subcomands are available for '$0':
    genkeys                 Generate, sign, or refresh certificates for keys
    keyinfo                 Print information about the current key set

EOF
}

sub c_genkeys {
    GetOptions(
        'd|key-directory' => \my $keys_directory,
        'r|refresh-cert' => \my $refresh_cert,
        'g|gen-new-keys' => \my $gen_new_keys,
        'p|preserve-eid' => \my $preserve_entity_id,
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
        $sc = OSiRIS::AccessAssertion::RSA::Certificate->new("$keys_directory/sign.crt");
        $sk = OSiRIS::AccessAssertion::RSA::Key->new({ cert => $sc, file => "$keys_directory/sign.key"});

        # crypto pair
        $ec = OSiRIS::AccessAssertion::RSA::Certificate->new("$keys_directory/enc.crt");
        $ek = OSiRIS::AccessAssertion::RSA::Key->new({ cert => $ec, file => "$keys_directory/enc.key"});

        if ($refresh_cert) {
            my $key_config = $sc->config(force => 1, type => "sig");
            self_sign_key(
                $key_config, 
                "$keys_directory/sign.key", 
                "$keys_directory/sign.$file_time.crt",
            );
            system("rm", "$keys_directory/sign.crt");
            system("ln", '-s', "$keys_directory/sign.$file_time.crt", "$keys_directory/sign.crt");

            $key_config->{type} = "enc";
            self_sign_key(
                $key_config, 
                "$keys_directory/enc.key", 
                "$keys_directory/enc.$file_time.crt",
            );
            system("rm", "$keys_directory/enc.crt");
            system("ln", '-s', "$keys_directory/enc.$file_time.crt", "$keys_directory/enc.crt");
            print "[info] new certificate generated for @{[$sc->common_name]} (@{[$sc->thumbprint]})\n";
        } elsif ($gen_new_keys) {
            # clobber the configuration in the certificate if we're generating new keys.
            my $key_config = {
                common_name => $entity_id ? $entity_id : "urn:uuid:@{[new_uuid()]}",
                type => "sig",
            };
            
            if ($preserve_entity_id && !$entity_id) {
                $key_config->{common_name} = $sc->common_name;
            }
            
            foreach my $opt (qw/ country state locality organization organizational_unit 
              email_address subject_alternate_names /) {
               if (exists $config->{$opt} && $config->{$opt}) {
                   $key_config->{$opt} = $config->{$opt};
               }
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

            $sc = OSiRIS::AccessAssertion::RSA::Certificate->new("$keys_directory/sign.crt");
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
            type => "sig",
        };
        foreach my $opt (qw/ country state locality organization organizational_unit 
          email_address subject_alternate_names /) {
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
        $sc = OSiRIS::AccessAssertion::RSA::Certificate->new("$keys_directory/sign.crt");
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
    -p, --preserve-eid      When using --gen-new-keys, uses the Entity ID from the
                            existing certificate.  Specifying --entity-id explicitly
                            will override this option.

One of these parameters may also be specified:
    -r, --refresh-cert      Refresh the existing self signed certificate using the 
                            configuration of the existing certificate
    -g, --gen-new-keys      Generate a new private key and sign it using config in
                            $ENV{AA_HOME}/etc/aa_services.conf 

EOF
}

sub usage {
    return <<"EOF";
Usage: $0 [SUBCOMMAND]

These subcomands are available for '$0':
    genkeys                 Generate, sign, or refresh certificates for keys
    keyinfo                 Print information about the current key set

EOF
}