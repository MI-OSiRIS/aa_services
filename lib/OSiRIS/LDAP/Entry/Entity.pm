package OSiRIS::LDAP::Entry::Entity;

use Mojo::Base 'OSiRIS::LDAP::Entry';

has OBJECT_CLASS => sub { 'osirisEntity' };

sub type {
    (split(/::/, ref shift))[-1];
}

1;