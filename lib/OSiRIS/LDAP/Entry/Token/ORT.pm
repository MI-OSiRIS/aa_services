package OSiRIS::LDAP::Entry::Token::ORT;
use Mojo::Base 'OSiRIS::LDAP::Entry::Token';

has OBJECT_CLASS => sub { 'osirisRefreshToken' };
has BASE_DN => sub { 'ou=ORTs, ou=Tokens, dc=osris, dc=org' };
has [qw/ oaa oaa_digest /];

1;