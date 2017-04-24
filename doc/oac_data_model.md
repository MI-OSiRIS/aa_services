OSiRIS Access Control Data Model
================================

Given the [third primary assumption](oaa_implementation_assumptions_apr_2017.md) the data model is being refactored to be based on LDAP.  Each type of entry will be given its own class that is part of a class hierarchy that closely maps the `objectClass` entries defined in the [ldap schema](../schema/ldap/openldap/conf/osiris.schema).  As tokens will be represented as full LDAP objects now instead of strings in LDAP and searchable indexed data in an RDBMS, they will be stored in the principals' entries as DNs that refer to those Token entries.

## OSiRIS::LDAP::Entry

This is the base class for every OSiRIS "Entry" object, it has methods in it that will be common across all objects, such as `save()`, `add_or_replace()`, `changetype()`, etc.  This class will inherit from the `Net::LDAP::Entry` class.

## OSiRIS::LDAP::Entry::Entity

This is the base class for any *Entity* within the OSiRIS system, and will include accessors and mutators for all attributes allowed by the `osirisEntity` base class.  An osirisEntity MUST provide two attributes, `cn`, and `osirisUniqueID`, and so must all of the following sub classes.  There currently exist six different types of entities, each with their own required attributes (in addition to those required by `osirisEntity`).  Please note that attributes listed as "Required" must be present at the time the entry is added.  These are defined below.

### People

| **Property** | **Value** |
| ------------ | --------- |
| Base DN      | *ou=People, dc=osris, dc=org* |
| Object Classes | `osirisPerson`, `eduPerson`, `posixAccount`, `shadowAccount` |
| Perl Class | OSiRIS::LDAP::Entry::Entity::Person |
| Required Attributes | `sn`, `givenName`, `eduPersonPrincipalName`, `osirisOrganizationalAffiliations`, `uid`, `userPassword`, `mail` |
 
### Groups, from COmanage or manually created

| **Property** | **Value** |
| ------------ | --------- |
| Base DN      | *ou=Groups, dc=osris, dc=org* |
| Object Classes | `osirisGroup`, `posixGroup` |
| Perl Class | OSiRIS::LDAP::Entry::Entity::Group |
| Required Attributes | none other than those required by `osirisEntity` |

### Automata, accounts that run daemons or *ou=Automata, dc=osris, dc=org*, `osirisAutomaton`



 * Organizations - *ou=Organizations, dc=osris, dc=org*, `osirisOrganization`
 * Institutions - *ou=EduOrgs, dc=osris, dc=org*, `osirisEduOrg`, `eduOrg`
 * Authority Systems *ou=Authorities, dc=osris, dc=org*
    * Central Authority `osirisCentralAuthority`
    * Resource Authorities `osirisResourceAuthority`

 
