package OSiRIS::LDAP::Entry::Token::ORT;
use Mojo::Base 'OSiRIS::LDAP::Entry::Token';

has OBJECT_CLASS => sub { 'osirisRefreshToken' };
has [qw/ oaa oaa_digest /];

1;