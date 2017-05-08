package OSiRIS::LDAP::Entry::Entity::Person;

use Mojo::Base 'OSiRIS::LDAP::Entry::Entity';

has OBJECT_CLASS => sub { 'osirisPerson' };

1;