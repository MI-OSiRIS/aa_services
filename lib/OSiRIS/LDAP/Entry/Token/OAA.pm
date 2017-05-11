package OSiRIS::LDAP::Entry::Token::OAA;
use Mojo::Base 'OSiRIS::LDAP::Entry::Token';

has OBJECT_CLASS => sub { 'osirisAccessAssertion' };
has BASE_DN => sub { 'ou=OAAs, ou=Tokens, dc=osris, dc=org' };

1;