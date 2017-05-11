package OSiRIS::LDAP::Entry::Entity::Authority::Central;
use Mojo::Base 'OSiRIS::LDAP::Entry::Entity';

has OBJECT_CLASS => sub { 'osirisCentralAuthority' };
has BASE_DN => sub { 'ou=Central, ou=Authorities, dc=osris, dc=org' };

1; 