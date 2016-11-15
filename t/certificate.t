use Test::More;
use OSiRIS::AccessAssertion::Util qw/new_uuid :crypto/;
use Mojo::Util qw/slurp b64_decode/;

use_ok('OSiRIS::AccessAssertion::Certificate', 'unharness');
my $alice_cn = 'urn:uuid:' . new_uuid();
gen_rsa_keys({type => 'enc', common_name => $alice_cn}, '/tmp/alice_enc.key', '/tmp/alice_enc.crt');

# native load-from-PEM-file support
my $cert = OSiRIS::AccessAssertion::Certificate->new('/tmp/alice_enc.crt');
ok($cert->subject_locality eq 'Detroit', "testing new fangled certificate loading constructor");

# native load-from-PEM string support
my $cert2 = OSiRIS::AccessAssertion::Certificate->new(\slurp '/tmp/alice_enc.crt');
ok($cert2->subject_locality eq 'Detroit', "testing new fangled certificate loading constructor alt behavior");

# loads certs from DER encoding by default
my $cert3 = OSiRIS::AccessAssertion::Certificate->new(cert =>
    b64_decode(
        unharness(
            slurp(
                '/tmp/alice_enc.crt'
            )
        )
    )
);

ok($cert3->subject_locality eq 'Detroit', "testing default certificate loading constructor alt behavior");
ok($cert3->use eq "enc", "making sure this key is only good for encryption");
ok($cert3->is_osiris_certificate, "making sure the certificate has the MI-OSiRIS OID in its extended key usage");

gen_rsa_keys({type => 'sig', locality => 'Flint', common_name => $alice_cn}, '/tmp/alice_sig.key', '/tmp/alice_sig.crt');
my $cert4 = OSiRIS::AccessAssertion::Certificate->new('/tmp/alice_sig.crt');
ok($cert4->subject_locality eq 'Flint', "default overrides work");
ok($cert4->use eq "sig", "key is only good for signatures and non repudiation");
ok($cert4->is_osiris_certificate, "certificate has the MI-OSiRIS OID in extended key usage");

# we want the private keys now too...
use_ok('OSiRIS::AccessAssertion::Key');
my ($alice_sig_key, $alice_enc_key, $alice_sig_cert, $alice_enc_cert) = (
    OSiRIS::AccessAssertion::Key->new({ cert => '/tmp/alice_sig.crt', file => '/tmp/alice_sig.key'}),
    OSiRIS::AccessAssertion::Key->new({ cert => '/tmp/alice_enc.crt', file => '/tmp/alice_enc.key'}),
    OSiRIS::AccessAssertion::Certificate->new('/tmp/alice_sig.crt'),
    OSiRIS::AccessAssertion::Certificate->new('/tmp/alice_enc.crt')
);

#
# let's set up bob some keys if tests have passed thus far.
#
my $bob_cn = 'urn:uuid:' . new_uuid();
gen_rsa_keys({type => 'enc', common_name => $bob_cn}, '/tmp/bob_enc.key', '/tmp/bob_enc.crt');
gen_rsa_keys({type => 'sig', common_name => $bob_cn}, '/tmp/bob_sig.key', '/tmp/bob_sig.crt');
my ($bob_sig_key, $bob_enc_key, $bob_sig_cert, $bob_enc_cert) = (
    OSiRIS::AccessAssertion::Key->new({ cert => '/tmp/bob_sig.crt', file => '/tmp/bob_sig.key'}),
    OSiRIS::AccessAssertion::Key->new({ cert => '/tmp/bob_enc.crt', file => '/tmp/bob_enc.key'}),
    OSiRIS::AccessAssertion::Certificate->new('/tmp/bob_sig.crt'),
    OSiRIS::AccessAssertion::Certificate->new('/tmp/bob_enc.crt')
);    

my $cleartext = "T0pS3CrEt MEssaGe";
# encrypt cleartext for alice...
my $encoded_ciphertext = $alice_enc_cert->encrypt($cleartext);


my $signature = $bob_sig_key->sign($encoded_ciphertext);
ok($bob_sig_cert->verify($signature, $encoded_ciphertext), "verify that bob signed the encoded ciphertext");
ok($alice_enc_key->decrypt($encoded_ciphertext) eq $cleartext, "alice was able to decrypt bob's $cleartext");
eval {
    $alice_sig_cert->encrypt($cleartext);
};

like($@, qr/fatal/, "fatal error trying to encrypt with a signing key");

# reset.
undef $@;

eval {
    $bob_enc_cert->verify($signature, $encoded_ciphertext);
};

like($@, qr/fatal/, "fatal error trying to verify a signature with an encryption cert");
ok($bob_sig_cert->common_name eq $bob_enc_cert->common_name, "the encryption and signing certs have the same commonName");

diag $bob_sig_cert->expires_in_days;
diag $bob_sig_cert->pubkey_size;

unlink('/tmp/bob_sig.key');
unlink('/tmp/bob_sig.crt');
unlink('/tmp/bob_enc.key');
unlink('/tmp/bob_enc.crt');
unlink('/tmp/alice_sig.key');
unlink('/tmp/alice_sig.crt');
unlink('/tmp/alice_enc.key');
unlink('/tmp/alice_enc.crt');

done_testing();