package OSiRIS::LDAP::Entry::Entity::Automaton;

use Mojo::Base 'OSiRIS::LDAP::Entry::Entity';

has OBJECT_CLASS => sub { 'osirisAutomaton' };
has BASE_DN => sub { 'ou=Automata, dc=osris, dc=org' };

1; 