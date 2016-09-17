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

use Mojo::Util qw/slurp b64_decode b64u_decode monkey_patch/;
use Mojo::Base 'Crypt::X509';
use Crypt::PK::RSA;

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

sub verify {
    my ($self, $sig, $msg) = @_;
    return $self->pk->verify_message(b64u_decode($sig), $to_verify, 'SHA256', 'v1.5');
}

sub pubkey {
    my ($self) = @_;
    my $pk_obj;
    unless ($pk_obj = $self->{_pk_object}) {
        $pk_obj = $self->{_pk_object} = Crypt::PK::RSA->new(\Crypt::X509::pubkey($self));
    }
    return $pk_obj;
}

sub to_jwk {
    shift->pubkey->export_key_jwk('public');    
}

sub thumbprint {
    shift->pubkey->export_key_jwk_thumbprint('SHA256');
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