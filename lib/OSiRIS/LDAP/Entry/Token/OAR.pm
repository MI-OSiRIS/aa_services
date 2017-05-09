package OSiRIS::LDAP::Entry::Token::OAR;
use Mojo::Base 'OSiRIS::LDAP::Entry::Token';

has OBJECT_CLASS => sub { 'osirisAccessRequest' };

1;