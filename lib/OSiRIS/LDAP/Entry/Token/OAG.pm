package OSiRIS::LDAP::Entry::Token::OAG;
use Mojo::Base 'OSiRIS::LDAP::Entry::Token';

has OBJECT_CLASS => sub { 'osirisAccessGrant' };

1;