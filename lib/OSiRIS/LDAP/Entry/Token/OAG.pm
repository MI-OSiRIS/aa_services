package OSiRIS::LDAP::Entry::Token::OAG;
use Mojo::Base 'OSiRIS::LDAP::Entry::Token';

has OBJECT_CLASS => sub { 'osirisAccessGrant' };
has BASE_DN => sub { 'ou=OAGs, ou=Tokens, dc=osris, dc=org' };

1;