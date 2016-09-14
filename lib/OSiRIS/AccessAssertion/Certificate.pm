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

use Mojo::Base 'Crypt::X509';
use Crypt::PK::RSA;

sub pubkey {
    my ($self) = @_;
    my $pk_obj;
    unless ($pk_obj = $self->{_pk_object}) {
        $pk_obj = $self->{_pk_object} = Crypt::PK::RSA->new(\Crypt::X509::pubkey($self));
    }
    return $pk_obj;
}


1;