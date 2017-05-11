package OSiRIS::LDAP::Entry::Token;

use Mojo::Base 'OSiRIS::LDAP::Entry';

has OBJECT_CLASS => sub { 'osirisToken' };
has BASE_DN => sub { 'ou=Tokens, dc=osris, dc=org' };

sub type {
    (split(/::/, ref shift))[-1];
}

1;