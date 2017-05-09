package OSiRIS::LDAP::Entry::Token::OAA;

has OBJECT_CLASS => sub { 'osirisAccessAssertion' };

use Mojo::Base 'OSiRIS::LDAP::Entry::Token';

1;