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
use Mojo::Util qw/trim/;
use MIME::Base64 qw/encode_base64url decode_base64url/;
use Crypt::Digest qw/digest_data digest_data_hex/;
use Crypt::X509;
use Crypt::PK::RSA;

# define our signature and validation configurations
has crypto => sub { 
    return {
        'RS256' => {
            sign => sub {
                my ($sk, $to_sign) = @_;
                return encode_base64url($sk->sign_message($to_sign, 'SHA256', 'v1.5'), '');
            },
            verify => sub {
                my ($pk, $sig, $to_verify) = @_;
                return $pk->verify_message(decode_base64url($sig), $to_verify, 'SHA256', 'v1.5');
            }
        },
    };
};

=item new($target, $access, $sk) [B<constructor>]

=over 2

=item Arguments:

=over 2

=item * B<$access> - hashref to be json-ified, and signed.  as of right now it can be any set of values your application 
requires, stuff like who to grant access to, and what access to grant, maybe a not_before, not_after clause, and throw
an ID in for good measure.

=item * B<$sk> - secret (private) key in DER format.

=back

=item Returns: OSiRIS::AccessAssertion Object

=back

=cut

sub new {
    my ($access, $sk) = @_;


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

=item * B<$sk> - to_string is what actually does the signing, so if you didn't create this OAA with new() and/or
want to re-sign an existing one with a new key, you B<MAY> pass one in as an argument.  otherwise B<to_string> will
use the key you specified when you called new() to sign and generate the JWT.

=back

=item Returns: A JWT String

=back

=cut

sub to_string {
    my ($self) = @_;

    # default to an empty hashref
    my $access = $self->{access} eq "HASH" ? $self->{access} : {};

    my $header = encode_base64url(encode_json({
        alg => 'RS256',
        x5t => encode_base64url(digest_data('SHA256', b64_decode($self->config->{pem_string}))),
        x5u => $self->config->{front_door_url} . '/oaa/pubkey.pem',
    }), '');

    # scope the jwt to Mi-OSiRIS
    unless ($access->{aud} =~ /^urn\:MI-OSiRIS\:/) {
        $access->{aud} = 'urn:MI-OSiRIS:$access->{aud}';
    }

    $access = {
        sub => $access->{eppn},
        exp => time + $self->config->{session_length},
        nbf => time,
        iat => time,
        jti => $c->new_uuid,

        # let passed values override defaults
        %$access,

        # but don't let anything override the issuer
        iss => ('urn:MI-OSiRIS:' . trim `uname -n`),
    };


    my $token = $c->m->resultset("Academica::Plugin::OAuth2::Model::Token")->create({
        academica_user => $user->id,
        client => $client->id,
        unique_id => $jwt->{jti},
        signer_thumbprint => $c->thumbprint(b64_decode($c->oauth2->x509_string)),
        expire_time => $jwt->{exp},
    });

    # do user specific stuff here.
    if (my $password = delete $jwt->{_password}) {
        # they supplied a password... make sure it's for this user.
        if ($c->authenticate_user($user->userid, $password)) {
            # this is this user's password, this must be the intention of the caller
            my $key = $c->crypto_stream_key;
            my $enc_pw = $c->encrypt_pw($password, $key, $token->id);

            # the key goes in the database
            $token->auxiliary_secret($key);
            
            # but the encrypted password only ever goes into the token
            $jwt->{ap_cred} = $enc_pw;
        }
    }

    if (my $refresh = delete $jwt->{_refresh_token}) {
        $token->is_refresh_token(1);
    }

    # update the token in the database if we changed anything..
    if ($token->is_changed) {
        $token->update;
    }

    my $payload = encode_base64url(encode_json($jwt));
    my $sig = $crypto->{$c->oauth2->config->{signature_method}}->{sign}->($c->oauth2->rsa_sk, "$header.$payload");

    if ($json_serialization) {
        return encode_json({
            header => [$header],
            payload => $payload,
            signature => [$sig],
        });
    } else {
        return "$header.$payload.$sig";
    }
}

=pod

=back

=cut

1;
