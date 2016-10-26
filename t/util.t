use Test::More;

use_ok("OSiRIS::AccessAssertion::Util", ':all');

# test mojo::util import
ok(length(trim(" ")) == 0, "trim");
ok(camelize("hello_world") eq "HelloWorld", "camelize");
ok(b64u_encode("OSiRIS") eq "T1NpUklT", "b64u_encode");
ok(b64u_decode("T1NpUklT") eq "OSiRIS", "b64u_decode");
ok(a85_encode("OSiRIS") eq ":K(t*8Q,", "a85_encode");
ok(a85_decode(":K(t*8Q,") eq "OSiRIS", "a85_decode");
ok(length(new_crypto_stream_key()) == 32, "sane crypto_stream cipher key generation");
ok(length(random_bytes()) == 32, "32 random bytes");
ok(random_hex() =~ /^[0-9a-f]{32}$/i, "32 characters of random hex");
ok(random_b64() =~ /^[0-9a-z\/\+\=]{32}$/i, "32 characters of random base64");
ok(random_b64u() =~ /^[0-9a-z\-\_\=]{32}$/i, "32 characters of random base64url");
ok(random_a85() =~ /^[0-9a-z\!\#\$\%\&\(\)\*\+\-\;\<\=\>\?\@\^\_\`\{\|\}\~\"\'\,\.\/\:\[\]\\]{32}$/i, "32 characters of random a85");

#
# Quick test of crypto_stream_xor
#
my $secret = "Dirty Secret";
my $k1 = new_crypto_stream_key();
my $n1 = new_crypto_stream_nonce();
my $ciphertext = crypto_stream_xor($secret, $n1, $k1);
ok(crypto_stream_xor($ciphertext, $n1, $k1) eq $secret, "round trip crypto_stream_xor");

my ($key_file, $cert_file) = gen_rsa_keys({
    country => "US",
    state => "Michigan",
    locality => "Hell", # hey, it's a place
    organization => "Wayne State University",
    organizational_unit => "MI-OSiRIS",
    email_address => 'ak1520@wayne.edu',
    bits => 4096,
    days => 7300,
    force => 1,
}, '/tmp/test.key', '/tmp/test.crt');

use_ok("OSiRIS::AccessAssertion::Certificate");

my $rsa_cert = OSiRIS::AccessAssertion::Certificate->new($cert_file);
ok($rsa_cert->subject_locality eq "Hell", "sanity checking gen_rsa_keys");

unlink('/tmp/test.key');
unlink('/tmp/test.crt');

done_testing();