package OSiRIS::LDAP::Entry::Token::OAT;
use Mojo::Base 'OSiRIS::LDAP::Entry::Token';

has OBJECT_CLASS => sub { 'osirisAccessToken' };
has [qw/ oaa oaa_digest /];

1;