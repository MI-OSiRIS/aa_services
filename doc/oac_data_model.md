OSiRIS Access Control Data Model
================================

## Attributes that should be indexed
| **Attribute** | **Index Type(s)** |
| ------------- | -------------- |
| `cn` | *sub*, *eq*, *pres*
| `sn` | *sub*, *eq*
| `eduPersonPrincipalName` (`eppn`) | *sub*, *eq*
| `ouid` (`osirisUniqueID`) | *eq*, *pres*
| `osirisCOmanageID` | *eq*
| `osirisKeyThumbprint` | *eq*, *pres*
| `osirisTokenThumbprint` | *eq*, *pres*
| `osirisEduOrganizationalAffiliates` | *eq*
| `osirisOrganizationalAffiliates` | *eq*

Given the [third primary assumption](oaa_implementation_assumptions_apr_2017.md) the data model is being refactored to be based on LDAP.  Each type of entry will be given its own class that is part of a class hierarchy that closely maps the `objectClass` entries defined in the [ldap schema](../schema/ldap/openldap/conf/osiris.schema).  As tokens will be represented as full LDAP objects now instead of strings in LDAP and searchable indexed data in an RDBMS, they will be stored in the principals' entries as DNs that refer to those Token entries.

## OSiRIS::LDAP::Entry

This is the base class for every OSiRIS "Entry" object, it has methods in it that will be common across all objects, such as `save()`, `add_or_replace()`, `changetype()`, etc.  This class will inherit from the `Net::LDAP::Entry` class.

## OSiRIS::LDAP::Entry::Entity

This is the base class for any *Entity* within the OSiRIS system, and will include accessors and mutators for all attributes allowed by the `osirisEntity` base class.  An osirisEntity MUST provide two attributes, `cn`, and `osirisUniqueID`, and so must all of the following sub classes.  There currently exist six different types of entities, and so will all receive the `osirisEntity` object class which requires two attributes `osirisUniqueId` and `cn`, additional object classes typically assigned to an entity type are listed, each may have their own required attributes and those are listed too.

Please note that "Required" must be present at the time the entry is added to the directory OR at the time that the `osiris` prefixed `objectClass` is added to an existing entry.  It should be most common for these entries to be created with these attributes filled out, though.  Entity types, and their corresponding info follow.

### People

| **Property** | **Value** |
| ------------ | --------- |
| Base DN      | *ou=People, dc=osris, dc=org* |
| Object Classes | `osirisPerson`, `eduPerson`, `posixAccount`, `shadowAccount`
| Perl Class | `OSiRIS::LDAP::Entry::Entity::Person` |
| Required Attributes | `sn`, `givenName`, `eduPersonPrincipalName`, `osirisOrganizationalAffiliations`, `uid`, `userPassword`, `mail` |

### Automata, accounts that run daemons, are used for monitoring, or to give software access to OSiRIS resources

| **Property** | **Value** |
| ------------ | --------- |
| Base DN      | *ou=Automata, dc=osris, dc=org* |
| Object Classes | `osirisAutomaton`, `posixAccount`, `shadowAccount` |
| Perl Class | `OSiRIS::LDAP::Entry::Entity::Automaton` |
| Required Attributes | none other than those required by `osirisEntity` |

### Groups, from COmanage or manually created

I expect these will primarily be used as posixGroups as they no longer will have any association with a COmanage Group.  These are the only entity type that does not have to be an `osirisEntity` but the `MUST` attributes `cn` and `osirisUniqueID` are enforced for `osirisGroup as well`

| **Property** | **Value** |
| ------------ | --------- |
| Base DN      | *ou=Groups, dc=osris, dc=org* |
| Object Classes | `osirisGroup`, `posixGroup` |
| Perl Class | `OSiRIS::LDAP::Entry::Entity::Group` |
| Required Attributes | none other than those required by `osirisEntity` |

### Organizations

`osirisAssociatedCOGroup` is a single value field that can only belong to an `osirisOrganization`.  This is what maps COmanage to LDAP.  An `osirisPerson` may belong to one or many `osirisOrganizations` which are mapped to COmanage groups via `osirisAssociatedCOGroup`.  `osirisOrganizations` may also have one or many `osirisEduOrganizationalAffiliations` with `osirisEduOrganizations`

Organizations will typically map to **COmanage** organizations / science domains, but the most important distinction is that these `osirisOrganization`s *are local to OSiRIS*.  They may (and typically should) have one or more institutional affiliations specified by `osirisEduOrganizationalAffiliation`, and if they were created by the COmanage integration they will have `osirisAssociatedCOGroup` filled out as well.  None of these are necessary at create time, though.

| **Property** | **Value** |
| ------------ | --------- |
| Base DN      | *ou=Organizations, dc=osris, dc=org* |
| Object Classes | `osirisOrganization`, `osirisGroup` |
| Perl Class | `OSiRIS::LDAP::Entry::Entity::Organization` |
| Required Attributes | none other than those required by `osirisEntity` |

### EduOrganizations / Institutions

| **Property** | **Value** |
| ------------ | --------- |
| Base DN      | *ou=EduOrganizations, dc=osirs, dc=org* |
| Object Classes | `osirisEduOrganization`, `osirisGroup` |
| Perl Class | `OSiRIS::LDAP::Entry::Entity::EduOrganization` |
| Required Attributes | none other than those required by `osirisEntity` |

### Authoritative Systems - Central Authorities

| **Property** | **Value** |
| ------------ | --------- |
| Base DN      | *ou=Central, ou=Authorities, dc=osirs, dc=org* |
| Object Classes | `osirisCentralAuthority` |
| Perl Class | `OSiRIS::LDAP::Entry::Entity::CentralAuthority` |
| Required Attributes | `osirisKeyThumbprint`, `osirisOakEndpoint`, `osirisSigningCertificate`, `osirisEncryptionCertificate` |

### Authoritative Systems - Resource Authorities (Providers)

| **Property** | **Value** |
| ------------ | --------- |
| Base DN      | *ou=Resource, ou=Authorities, dc=osirs, dc=org* |
| Object Classes | `osirisResourceAuthority` |
| Perl Class | OSiRIS::LDAP::Entry::Entity::ResourceAuthority |
| Required Attributes | `osirisKeyThumbprint`,  `osirisSigningCertificate`, `osirisEncryptionCertificate`, `osirisStpEndpoint` |

## OSiRIS::LDAP::Entry::Token

All tokens will be assumed to have the `osirisToken` object class but will also have their corresponding object class assigned as well. 
The Perl Base Class for tokens is `OSiRIS::LDAP::Entry::Token`, and the base DN is `ou=Tokens,dc=osris,dc=org`.

### OSiRIS Access Requests (OARs)
| **Property** | **Value** |
| ------------ | --------- |
| Base DN      | *ou=OARs, ou=Tokens, dc=osris, dc=org* |
| Object Classes | `osirisAccessRequest` |
| Perl Class | `OSiRIS::LDAP::Entry::Token::OAR` |
| Required Attributes | `osirisTokenNotBefore`, `osirisTokenNotAfter`, `osirisCentralAuthorityDN`, `osirisPendingActionFromDN` |

### OSiRIS Access Grants (OAGs)
| **Property** | **Value** |
| ------------ | --------- |
| Base DN      | *ou=OAGs, ou=Tokens, dc=osris, dc=org* |
| Object Classes | `osirisAccessGrant` |
| Perl Class | `OSiRIS::LDAP::Entry::Token::OAG` |
| Required Attributes | `osirisTokenNotBefore`, `osirisTokenNotAfter`, `osirisCentralAuthorityDN`, `osirisPendingActionFromDN`, `osirisResourceAuthorityDN` |

### OSiRIS Access Assertions (OAAs)
| **Property** | **Value** |
| ------------ | --------- |
| Base DN      | *ou=OAAs, ou=Tokens, dc=osris, dc=org* |
| Object Classes | `osirisAccessAssertion` |
| Perl Class | `OSiRIS::LDAP::Entry::Token::OAA` |
| Required Attributes | `osirisTokenRequestorSignature`, `osirisTokenCentralAuthoritySignature`, `osirisTokenNotBefore`, `osirisTokenNotAfter`, `osirisCentralAuthorityDN`, `osirisResourceAuthorityDN` |

### OSiRIS Access Tokens (OATs)
| **Property** | **Value** |
| ------------ | --------- |
| Base DN      | *ou=OATs, ou=Tokens, dc=osris, dc=org* |
| Object Classes | `osirisAccessToken` |
| Perl Class | `OSiRIS::LDAP::Entry::Token::OAT` |
| Required Attributes | `osirisTokenNotBefore`, `osirisTokenNotAfter`, `osirisAccessAssertions`, `osirisTokenThumbprint` |

### OSiRIS Refresh Tokens (ORTs)
| **Property** | **Value** |
| ------------ | --------- |
| Base DN      | *ou=ORTs, ou=Tokens, dc=osris, dc=org* | 
| Object Classes | `osirisRefreshToken` |
| Perl Class | `OSiRIS::LDAP::Entry::Token::ORT` |
| Required Attributes | `osirisTokenNotBefore`, `osirisTokenNotAfter`, `osirisAccessAssertions`, `osirisTokenThumbprint` |

