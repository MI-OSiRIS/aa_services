package OSiRIS::AccessAssertion::Key;

# Class that encapsulates an RSA key used for creating OSiRIS Access 
# Assertions
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

use Mojo::Base 'Crypt::PK::RSA';
use Carp qw/croak/;
use OSiRIS::AccessAssertion::Util qw/b64u_decode b64u_encode encode_json digest_data monkey_patch/;
use OSiRIS::AccessAssertion::Certificate;

# since our object's a scalar ref, we can store our corresponding certificates here in this
# global hash
my %certs;

sub new {
    my ($class, $arg) = @_;
    my $self;
    if (ref $arg eq "HASH") {
        if (my $file = delete $arg->{file}) {
            $self = bless(Crypt::PK::RSA->new($file), $class);
        } elsif (my $string = delete $arg->{string}) {
            $self = bless(Crypt::PK::RSA->new(\$string), $class);
        } else {
            croak "[fatal] no key 'file' or 'string' specified\n";
        }

        # the cert has info about our capabilities, so if it was specified along side us let's stash it.
        if (my $cert = delete $arg->{cert}) {
            unless (ref($cert) eq "OSiRIS::AccessAssertion::Certificate") {
                $cert = OSiRIS::AccessAssertion::Certificate->new($cert);
            }
            $self->cert($cert);
        }
    } else {
        $self = bless(Crypt::PK::RSA->new($arg), $class);
    }
    return $self;
}

sub cert {
    my ($self, $cert) = @_;
    if ($cert) {
        $certs{$self} = $cert;
    }
    return $certs{$self};
}

sub sign {
    my ($self, $msg) = @_;
    if (my $cert = $self->cert) {
        unless ($cert->can_sign) {
            croak "[fatal] attempt to sign with a keypair meant for use '@{[$cert->use]}'\n";
        }
    }
    return b64u_encode($self->sign_message($msg, 'SHA256', 'v1.5'), '');
}

sub decrypt {
    my ($self, $msg) = @_;
    if (my $cert = $self->cert) {
        unless ($cert->can_encrypt) {
            croak "[fatal] attempt to decrypt with a keypair meant for use '@{[$cert->use]}'\n";
        }
    }
    return (Crypt::PK::RSA::decrypt($self, b64u_decode($msg), 'oaep', 'SHA256'));
}

1;