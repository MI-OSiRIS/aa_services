use Test::More;
use OSiRIS::AccessAssertion::Util qw/:crypto/;
use Mojo::Util qw/slurp b64_decode/;

use_ok('OSiRIS::AccessAssertion::Certificate');

gen_rsa_keys({}, '/tmp/test.key', '/tmp/test.crt');

# native load-from-PEM-file support
my $cert = OSiRIS::AccessAssertion::Certificate->new('/tmp/test.crt');
ok($cert->subject_locality eq 'Detroit', "testing new fangled certificate loading constructor");

# native load-from-PEM string support
my $cert2 = OSiRIS::AccessAssertion::Certificate->new(\slurp '/tmp/test.crt');
ok($cert2->subject_locality eq 'Detroit', "testing new fangled certificate loading constructor alt behavior");

# loads certs from DER encoding by default
my $cert3 = OSiRIS::AccessAssertion::Certificate->new(cert =>
    b64_decode(
        unharness(
            slurp(
                '/tmp/test.crt'
            )
        )
    )
);

ok($cert3->subject_locality eq 'Detroit', "testing default certificate loading constructor alt behavior");

# cleanup
unlink('/tmp/test.key');
unlink('/tmp/test.crt');

done_testing();