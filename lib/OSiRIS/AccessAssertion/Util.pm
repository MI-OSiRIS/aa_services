package OSiRIS::AccessAssertion::Util;

# Utility Class for OSiRIS Access Assertions
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

OSiRIS::AccessAssertion::Util - A utility class for dealing with the multiple types
of OSiRIS Access Assertions (OAR, OAG, OAA, OAT and ORTs)

=head1 FUNCTIONS / EXPORTS

=over 2

=cut

use Mojo::Base 'Mojo::Util';
use Mojo::Util @Mojo::Util::EXPORT_OK;
use Mojo::JSON qw/to_json from_json encode_json decode_json/;

use OSiRIS::AccessAssertion::Certificate;
use Crypt::PK::RSA;
use Crypt::Digest qw/digest_data digest_data_hex digest_file digest_file_hex/;
use Crypt::Sodium;

use MIME::Base64 qw/encode_base64url decode_base64url/;
use UUID::Tiny;
use Carp qw/croak/;

use Exporter 'import';

our @EXPORT_OK = (
    @Mojo::Util::EXPORT_OK,
    # crypto functions
    qw/
        new_crypto_stream_key new_crypto_stream_nonce crypto_stream_xor gen_rsa_keys gen_self_signed_rsa_pair
        load_rsa_pair load_rsa_key load_rsa_cert
    /,
    # encoding functions
    qw/
        a85_encode a85_decode b64u_encode b64u_decode harness unharness armor unarmor to_json from_json encode_json 
        decode_json
    /,
    # random string generators
    qw/
        random_bytes random_hex random_a85 random_b64 random_b64u
    /,
);

our %EXPORT_TAGS = (
    all => [@EXPORT_OK],
    crypto => [qw/
        new_crypto_stream_key new_crypto_stream_nonce crypto_stream_xor gen_rsa_keys gen_self_signed_rsa_pair
        load_rsa_pair load_rsa_key load_rsa_cert harness unharness armor unarmor
    /],
    encoding => [qw/
        to_json from_json encode_json decode_json encode decode b64_encode b64_decode a85_encode a85_decode
        b64u_encode b64u_decode harness unharness armor unarmor
    /],
    random => [qw/random_bytes random_hex random_a85 random_b64 random_b64u/],
    mojo => [@Mojo::Util::EXPORT_OK],
);

my @OPENSSL_DEFAULTS = (
    country => "US",
    state => "Michigan",
    locality => "Detroit",
    organization => "Wayne State University",
    organizational_unit => "MI-OSiRIS",
    email_address => 'ak1520@wayne.edu',
    bits => 4096,
    days => 7300,
);

# Aliases
monkey_patch(__PACKAGE__, 'unharness', \&OSiRIS::AccessAssertion::Certificate::_unharness);
monkey_patch(__PACKAGE__, 'b64u_encode', \&encode_base64url);
monkey_patch(__PACKAGE__, 'b64u_decode', \&decode_base64url);
monkey_patch(__PACKAGE__, 'armor', \&harness);
monkey_patch(__PACKAGE__, 'unarmor', \&unharness);
monkey_patch(__PACKAGE__, 'gen_rsa_keys', \&gen_self_signed_rsa_pair);

sub opaque_block {
    my ($hr, $key) = @_;
    return b64u_encode(crypto_stream_xor());
}

sub gen_self_signed_rsa_pair {
    my ($user_config, $key_file, $cert_file) = @_;

    my ($force, $config);
    if (ref $user_config eq "HASH") {
        $force = delete $user_config->{force};
        $config = {
            @OPENSSL_DEFAULTS,

            # allow their settings to override defaults
            %$user_config
        };
    } else {
        $config = { @OPENSSL_DEFAULTS };
    }

    if (-e $key_file && !$force) {
        croak "[fatal] $key_file exists, please remove before calling gen_self_signed_rsa_pair or pass force => 1 in options\n";
    }

    if (-e $cert_file && !$force) {
        croak "[fatal] $cert_file exists, please remove before calling gen_self_signed_rsa_pair or pass force => 1 in options\n";
    }

    unless (exists $config->{common_name} && $config->{common_name}) {
        $config->{common_name} = "urn:uuid:" . new_uuid();
    }

    open my $ossl_cfg, '>', "/tmp/osiris_openssl_config.$$.conf";
    print $ossl_cfg "[ req ]\n";
    print $ossl_cfg "default_bits = $config->{bits}\n";
    print $ossl_cfg "distinguished_name = req_distinguished_name\n";
    print $ossl_cfg "prompt = no\n\n";

    print $ossl_cfg "[ req_distinguished_name ]\n";
    print $ossl_cfg "C=$config->{country}\n";
    print $ossl_cfg "ST=$config->{state}\n";
    print $ossl_cfg "L=$config->{locality}\n";
    print $ossl_cfg "O=$config->{organization}\n";
    print $ossl_cfg "OU=$config->{organizational_unit}\n";
    print $ossl_cfg "CN=$config->{common_name}\n";
    print $ossl_cfg "emailAddress=$config->{email_address}\n";
    close $ossl_cfg;

    system("openssl genrsa -out $key_file $config->{bits} >/dev/null 2>&1");
    system("openssl req -new -x509 -key $key_file -out $cert_file -days $config->{days} -sha256 -config /tmp/osiris_openssl_config.$$.conf >/dev/null 2>&1");

    unlink("/tmp/osiris_openssl_config.$$.conf") if -e "/tmp/osiris_openssl_config.$$.conf";

    return load_rsa_pair($key_file, $cert_file);
}

sub load_rsa_pair {
    my ($key_file, $cert_file) = @_;
    if (-e $key_file && -e $cert_file) {
        my $key_text = slurp($key_file);
        my $sk = Crypt::PK::RSA->new(\$key_text);

        my $cert_text = unharness(slurp($cert_file));
        my $x509 = OSiRIS::AccessAssertion::Certificate->new( cert => b64_decode( $cert_text) );

        return ($sk, $x509);
    }

    return undef;
}

sub load_rsa_key {
    my ($key_file) = @_;
    if (-e $key_file) {
        my $key_text = slurp($key_file);
        return Crypt::PK::RSA->new(\$key_text);
    }

    return undef;
}

sub load_rsa_cert {
    my ($cert_file) = @_;
    if (-e $cert_file) {
        my $cert_text = unharness(slurp($cert_file));
        return OSiRIS::AccessAssertion::Certificate->new( cert => b64_decode( $cert_text ) );
    }

    return undef;
}

sub new_uuid {
    return uc(create_UUID_as_string(UUID_V4));
}

# random character generators, more flavors than anyone should ever need
sub random_bytes {
    my ($length) = @_;
    return randombytes_buf($length // 32);
}

sub random_hex {
    my ($length) = @_;
    return substr(unpack('H*', random_bytes($length)), 0, $length // 32);
}

sub random_a85 {
    my ($length) = @_;
    return substr(a85_encode(random_bytes($length)), 0, $length // 32);
}

sub random_b64 {
    my ($length) = @_;
    return substr(b64_encode(random_bytes($length), ""), 0, $length // 32);
}

sub random_b64u {
    my ($length) = @_;
    return substr(encode_base64url(random_bytes($length), ''), 0, $length // 32);
}

sub new_crypto_stream_nonce {
    return randombytes_buf(crypto_stream_NONCEBYTES);
}

sub new_crypto_stream_key {
    return randombytes_buf(crypto_stream_KEYBYTES);
}

sub a85_encode {
    my ($in, $opt) = @_;

    my $_space_no = unpack 'N', ' ' x 4;

    my $compress_zero = exists $opt->{compress_zero} ? $opt->{compress_zero} : 1;
    my $compress_space = $opt->{compress_space};

    my $padding = -length($in) % 4;
    $in .= "\0" x $padding;
    my $out = '';

    for my $n (unpack 'N*', $in) {
        if ($n == 0 && $compress_zero) {
            $out .= 'z';
            next;
        }
        if ($n == $_space_no && $compress_space) {
            $out .= 'y';
            next;
        }

        my $tmp = '';
        for my $i (reverse 0 .. 4) {
            my $mod = $n % 85;
            $n = int($n / 85);
            vec($tmp, $i, 8) = $mod + 33;
        }
        $out .= $tmp;
    }

    $padding or return $out;

    $out =~ s/z\z/!!!!!/;
    substr $out, 0, length($out) - $padding
}

sub a85_decode {
    my ($in) = @_;

    for ($in) {
        tr[ \t\r\n\f][]d;
        s/z/!!!!!/g;
        s/y/+<VdL/g;
    }

    my $padding = -length($in) % 5;
    $in .= 'u' x $padding;
    my $out = '';

    for my $n (unpack '(a5)*', $in) {
        my $tmp = 0;
        for my $i (unpack 'C*', $n) {
            $tmp *= 85;
            $tmp += $i - 33;
        }
        $out .= pack 'N', $tmp;
    }

    substr $out, 0, length($out) - $padding
}

sub harness {
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

1;