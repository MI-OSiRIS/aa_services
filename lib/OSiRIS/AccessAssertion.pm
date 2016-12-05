package OSiRIS::AccessAssertion;

# Object for parsing, validating, and managing OSiRIS Access Assertions
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

=pod

=head1 NAME

OSiRIS::AccessAssertion - Class for parsing, validating, and amanaging OSiRIS Access
Assertion (OAA) objects

=head1 OVERVIEW

OAAs are a form of L<JSON Web Token|https://jwt.io> that are signed by a central OSiRIS
authority and instruct services running on registered OSiRIS resources to configure their
resources accordingly.  The two primary users of this library are the B<St. Peter Daemon>
which acts as the primary consumer of OAAs and the B<OSiRIS Access Keyring Daemon> which 
issues, stores, and delivers OAAs at hopefully appropriate times.

At this point OAAs are all RS256 JWTs.  Any JWT library should be able to parse and 
validate an OAA, not sure what you'd do with it though.  Maybe grant us access to your 
ultra fast resources?!  That'd be awesome.

=head1 METHODS

=over 2

=cut

use Mojo::Base -base;
use Mojo::Log;
use OSiRIS::Config;
use OSiRIS::Model;
use OSiRIS::AccessAssertion::RSA::Certificate;
use OSiRIS::AccessAssertion::RSA::Key;
use OSiRIS::AccessAssertion::Util qw/b64u_decode b64u_encode encode_json digest_data gen_rsa_keys slurp/;
use Carp qw/croak confess/;
use JSON::Validator;

our($sk_pem, $cert_pem, $sk, $cert, $config);

BEGIN { 
    unless ($ENV{AA_HOME}) {
        print "[debug] AA_HOME environment variable undefined, defaulting to /opt/osiris/aa_services\n" if $ENV{AA_DEBUG};
        $ENV{AA_HOME} = "/opt/osiris/aa_services";
    }
}


has log => sub { return Mojo::Log->new(path => "$ENV{AA_HOME}/var/log/aa_services.log", level => 'warn') };
has config => sub {
    unless ($config) {
        $config = OSiRIS::Config->parse("$ENV{AA_HOME}/etc/aa_services.conf");
    }
    return $config;
};
has my_key => sub { return $sk };
has my_cert => sub { return $cert };

# these are the types of assertions we can possibly be
has VALID_TYPES => sub {
    return {
        OAR => 'doc/schema/json/osiris_access_request.jsd',
        OAG => 'doc/schema/json/osiris_access_grant.jsd',
        OAA => 'doc/schema/json/osiris_access_assertion.jsd',
        OAT => 'doc/schema/json/osiris_access_token.jsd',
        ORT => 'doc/schema/json/osiris_refresh_token.jsd',
    }
};

# simple accessor/mutator methods
has ['type', 'access', 'target'];

=item new(%opts) [B<constructor>]

=over 2

=item Options:

=over 2

=item * B<access> - hashref to be json-ified, and signed.  as of right now it can be any set of values your application 
requires, stuff like who to grant access to, and what access to grant, maybe a not_before, not_after clause, and throw
an ID in for good measure.

=item * B<target> - thumbprint of the Central Authority or Resource Authority target

=item * B<type> - A string, representing the type of AccessAssertion this is, needs to be one of OAR, OAG, OAA, OAT, or 
ORT

=item * B<access> - A hashref representing the Access this assertion, must pass schema validation of the B<type> of 
assertion specified

=item * B<skip_initial_schema_check> - If true, the schema of <access> is not checked at object construction and only
at the JWT generation / sign time.

=back

=item Returns: OSiRIS::AccessAssertion Object

=back

=cut

sub new {
    my ($class, %opts) = @_;

    my $self = bless (\%opts, $class);

    unless (exists $self->{type} && exists $self->VALID_TYPES->{uc($self->{type})}) {
        croak "Invalid Access Assertion type specified; 'type' must be one of @{[join ', ', keys %{$self->VALID_TYPES}]}\n";
    }

    # keep the data clean
    $self->{type} = uc($self->{type});

    # if a target audience is specified, let's make sure we know who they are...
    if (exists $self->{target} && $self->{target}) {

    }
}

sub json_validator {
    my ($self) = @_;
    $self->{validator} = JSON::Validator->new() unless $self->{validator};
    $self->{validator}->schema($self->VALID_TYPES->{$self->{type}}) if exists self->VALID_TYPES->{$self->{type}};
    return $self->{validator};
}

sub type {
    my ($self, $type) = @_;
    if (exists($self->VALID_TYPES->{uc($type)})) {
        $self->{type} = uc($type);
    } else {
        confess "[error] Invalid Assertion Type provided: $type, leaving type set to $self->{type}\n";
    }
    return $self->{type};
}

=item verify($jwt_string, $cert) [B<constructor>]

=over 2

=item Arguments:

=over 2

=item * B<$jwt_string> - The JWT to be parsed in its stringified form

=item * B<$cert> - the certificate to be used to verify this JWT

=back

=item Returns: OSiRIS::AccessAssertion Object

=back

=cut

sub verify {
    my ($oaa, $cert) = @_;


}

=item to_string($sk [optional])

=over 2

=item Arguments:

=over 2 

=item * B<$sk> - serializes and signs this Assertion 

=back

=item Returns: A JWT String

=back

=cut

sub to_jwt {
    my ($self) = @_;

    # default to an empty hashref
    my $access = $self->{access} eq "HASH" ? $self->{access} : {};

    my $header = encode_base64url(encode_json({
        alg => 'RS256',
        x5t => $self->my_cert->thumbprint,
        x5u => $self->config->{front_door_url} . '/oaa/pubkey.pem',
    }), '');

    # scope the jwt to Mi-OSiRIS
    unless ($access->{aud} =~ /^\Qurn:oid:1.3.5.1.3.1.17128.313.1.1:\E/) {
        $access->{aud} = 'urn:oid:1.3.5.1.3.1.17128.313.1.1:$access->{aud}';
    }

    $access = {
        sub => $access->{eppn},
        exp => time + $self->config->{session_length},
        nbf => time,
        iat => time,
        jti => $self->new_uuid,

        # let passed values override defaults
        %$access,

        # but don't let anything override the issuer
        iss => $self->my_cert->osiris_key_thumbprint,
    };

    # update the token in the database if we changed anything..
    # if ($token->is_changed) {
    #     $token->update;
    # }

    #my $payload = encode_base64url(encode_json());
    #my $sig = "$header.$payload"

    # if ($json_serialization) {
    #     return encode_json({
    #         header => [$header],
    #         payload => $payload,
    #         signature => [$sig],
    #     });
    # } else {
    #     return "$header.$payload.$sig";
    # }
}

=pod

=back

=cut

1;
