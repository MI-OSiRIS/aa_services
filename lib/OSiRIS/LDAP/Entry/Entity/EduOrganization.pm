package OSiRIS::LDAP::Entry::Entity::EduOrganization;

use Mojo::Base 'OSiRIS::LDAP::Entry::Entity';

has OBJECT_CLASS => sub { 'osirisEduOrganization' };
has BASE_DN => sub { 'ou=eduOrganizations, dc=osris, dc=org' };

1; 