package OSiRIS::LDAP::Entry::Entity::Authority::Resource;
use Mojo::Base 'OSiRIS::LDAP::Entry::Entity';

has OBJECT_CLASS => sub { 'osirisResourceAuthority' };
has BASE_DN => sub { 'ou=Resource, ou=Authorities, dc=osris, dc=org' };

1; 