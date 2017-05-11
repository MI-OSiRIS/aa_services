package OSiRIS::LDAP::Entry::Entity::Person;

use Mojo::Base 'OSiRIS::LDAP::Entry::Entity';

has OBJECT_CLASS => sub { 'osirisPerson' };
has BASE_DN => sub { 'ou=People, dc=osris, dc=org' };

1;