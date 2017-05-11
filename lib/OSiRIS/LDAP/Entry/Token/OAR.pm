package OSiRIS::LDAP::Entry::Token::OAR;
use Mojo::Base 'OSiRIS::LDAP::Entry::Token';

has OBJECT_CLASS => sub { 'osirisAccessRequest' };
has BASE_DN => sub { 'ou=OARs, ou=Tokens, dc=osris, dc=org' };

1;