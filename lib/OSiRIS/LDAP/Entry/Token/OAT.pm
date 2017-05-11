package OSiRIS::LDAP::Entry::Token::OAT;
use Mojo::Base 'OSiRIS::LDAP::Entry::Token';

has OBJECT_CLASS => sub { 'osirisAccessToken' };
has BASE_DN => sub { 'ou=OATs, ou=Tokens, dc=osris, dc=org' };
has [qw/ oaa oaa_digest /];

1;