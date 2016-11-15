package OSiRIS::AccessAssertion::Certificate;

# Class that encapsulates an RSA certificate used for validating
# OSiRIS Access Assertions
#
# Authored by: Michael Gregorowicz
#
# Copyright 2016 Wayne State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use OSiRIS::AccessAssertion::Util qw/slurp b64_decode b64u_decode b64u_encode monkey_patch/;
use Mojo::Base 'Crypt::X509';
use Crypt::PK::RSA;
use Carp 'croak';
use Exporter 'import';

# give it an interface like the Crypt::PK modules but still work the old way, too...
sub new {
    my ($class, @opts) = @_;
    if (scalar(@opts) == 2 && $opts[0] eq "cert") {
        # default option, default behavior, passing 'cert' as the key in a key value
        # pair with the DER encoded certificate as the value.
        my $self = Crypt::X509::new($class, @opts);

        # stash this away
        $self->{_der_encoded} = $opts[1];

        return $self;
    } else {
        # if we just got passed one argument, let's act like Crypt::PK a bit more and 
        # load the certificate PEM encoded from a file or instantiate from a scalar ref
        if (scalar(@opts) == 1) {
            my ($file, $x509_string) = (@opts);

            if (ref $file eq "SCALAR") {
                $x509_string = $$file;
            } elsif (-e $file) {
                $x509_string = slurp $file;
            }

            my $der = b64_decode(_unharness($x509_string));
            my $self = Crypt::X509::new($class, cert => $der);
            $self->{_der_encoded} = $der;
            return $self;
        }
    }
    
    return undef;
}

# Aliases
monkey_patch(__PACKAGE__, 'pk', \&pubkey);
monkey_patch(__PACKAGE__, 'harness', \&_harness);
monkey_patch(__PACKAGE__, 'unharness', \&_unharness);
monkey_patch(__PACKAGE__, 'armor', \&harness);
monkey_patch(__PACKAGE__, 'unarmor', \&unharness);

# rename these locally
monkey_patch(__PACKAGE__, 'common_name', \&Crypt::X509::subject_cn);
monkey_patch(__PACKAGE__, 'organizational_unit', \&Crypt::X509::subject_ou);
monkey_patch(__PACKAGE__, 'organization', \&Crypt::X509::subject_org);
monkey_patch(__PACKAGE__, 'locality', \&Crypt::X509::subject_locality);
monkey_patch(__PACKAGE__, 'country', \&Crypt::X509::subject_country);
monkey_patch(__PACKAGE__, 'state', \&Crypt::X509::subject_state);
monkey_patch(__PACKAGE__, 'email', \&Crypt::X509::subject_email);

our @EXPORT_OK = (
    qw/harness unharness armor unarmor/,
);

sub expires {
    my ($self) = @_;
    return "@{[scalar gmtime($self->not_after)]} UTC";
}

sub expires_in_days {
    my ($self) = @_;
    return int(($self->not_after - time) / 86400);
}

sub valid {
    my ($self) = @_;
    if (time < $self->not_after && time > $self->not_before) {
        return 1;
    }
    return undef;
}

# does its best to reproduce the configuration that created this key
sub config {
    my ($self, %newopts) = @_;
    return {
        country => $self->country,
        state => $self->state,
        locality => $self->locality,
        organization => $self->organization,
        organizational_unit => $self->organizational_unit,
        email_address => $self->email,
        common_name => $self->common_name,
        bits => ($self->pubkey_size > 4096 ? 4096 : $self->pubkey_size > 2048 ? 2048 : 2048), # nothing smaller than 2048, sre.
        days => (($self->not_after - $self->not_before) / 86400),
        %newopts,
    }
}

sub is_osiris_certificate {
    my ($self) = @_;
    my $eku = $self->ExtKeyUsage;
    if (ref $eku eq "ARRAY" && scalar @$eku) {
        foreach my $e (@$eku) {
            if ($e eq "1.3.5.1.3.1.17128.313") {
                return 1;
            }
        }
    }
    return undef;
}

sub use {
    my ($self) = @_;
    my $ku = $self->KeyUsage;
    my $use;
    if (ref $ku eq "ARRAY" && scalar @$ku) {
        foreach my $e (@$ku) {
            if ($e eq "digitalSignature") {
                $use = $use ? "both" : "sig";
            } elsif ($e eq "dataEncipherment") {
                $use = $use ? "both" : "enc";
            }
        } 
    }
    return $use;
}

sub can_encrypt {
    my ($self) = @_;
    my $use = $self->use;
    if ($use eq "enc" || $use eq "both") {
        return 1;
    } elsif (!$use) {
        return 1;
    }
    return undef;
}

sub can_sign {
    my ($self) = @_;
    my $use = $self->use;
    if ($use eq "sig" || $use eq "both") {
        return 1;
    } elsif (!$use) {
        return 1;
    }
    return undef;
}

sub pubkey {
    my ($self) = @_;
    my $pk_obj;
    unless ($pk_obj = $self->{_pk_object}) {
        $pk_obj = $self->{_pk_object} = Crypt::PK::RSA->new(\Crypt::X509::pubkey($self));
    }
    return $pk_obj;
}

sub verify {
    my ($self, $sig, $msg) = @_;

    unless ($self->can_sign) {
        croak "[fatal] attempt to verify signature with a keypair meant for use '@{[$self->use]}'\n";
    }

    return $self->pk->verify_message(b64u_decode($sig), $msg, 'SHA256', 'v1.5');
}

sub encrypt {
    my ($self, $msg) = @_;
    unless ($self->can_encrypt) {
        croak "[fatal] attempt to encrypt with a keypair meant for use '@{[$self->use]}'\n";
    }
    return b64u_encode($self->pk->encrypt($msg, 'oaep', 'SHA256'));
}

sub to_jwk {
    return shift->pubkey->export_key_jwk('public');    
}

sub thumbprint {
    return shift->pubkey->export_key_jwk_thumbprint('SHA256');
}

sub osiris_key_thumbprint {
    my ($self) = @_;
    if ($self->can_sign) {
        return 'urn:oid:1.3.5.1.3.1.17128.313.1.1:' . $self->thumbprint;
    } else {
        croak "[fatal] you want the osiris_key_thumbprint of the signing public key\n";
    }
}

sub to_pem {
    my ($self) = @_;
    return _harness(b64_encode($self->{_der_encoded}, ''), "CERTIFICATE");
}

sub to_der {
    my ($self) = @_;
    return $self->{_der_encoded};
}

sub _harness {
    my ($b64, $type) = @_;
    return undef unless $type;

    # just make sure it's upper case
    $type = uc($type);

    my ($pos, @pem) = (0, "-----BEGIN $type-----");
    while (my $string = substr($b64, $pos, 64)) {
        push(@pem, $string);
        $pos += 64;
    }
    push(@pem, "-----END $type-----");

    return join("\n", @pem);
}

sub _unharness {
    my ($pem) = @_;
    my $unpem = join('', split("\n", $pem));
    $unpem =~ s/^-----[^-]+-----([^-]+).+$/$1/g;
    return $unpem;
}

1;