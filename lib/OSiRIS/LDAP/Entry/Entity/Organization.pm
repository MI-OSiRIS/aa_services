package OSiRIS::LDAP::Entry::Entity::Organization;
use Mojo::Base 'OSiRIS::LDAP::Entry::Entity';

has OBJECT_CLASS => sub { 'osirisOrganization' };
has BASE_DN => sub { 'ou=Organizations, dc=osris, dc=org' };

1;