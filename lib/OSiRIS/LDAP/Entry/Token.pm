package OSiRIS::LDAP::Entry::Token;

use Mojo::Base 'OSiRIS::LDAP::Entry';

has OBJECT_CLASS => sub { 'osirisToken' };

sub type {
    (split(/::/, ref shift))[-1];
}

1;