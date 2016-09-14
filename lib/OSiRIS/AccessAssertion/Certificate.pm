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

use Mojo::Util qw/slurp b64_decode/;
use Mojo::Base 'Crypt::X509';
use Crypt::PK::RSA;

# give it an interface like the Crypt::PK modules but still work the old way, too...
sub new {
    my ($class, @opts) = @_;
    if (scalar(@opts) == 2 && $opts[0] eq "cert") {
        # default option, default behavior, passing 'cert' as the key in a key value
        # pair with the DER encoded certificate as the value.
        return Crypt::X509::new($class, @opts);
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
            return Crypt::X509::new($class, cert => b64_decode(_unharness($x509_string)));
        }
    }
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

sub _unharness {
    my ($pem) = @_;
    my $unpem = join('', split("\n", $pem));
    $unpem =~ s/^-----[^-]+-----([^-]+).+$/$1/g;
    return $unpem;
}

1;