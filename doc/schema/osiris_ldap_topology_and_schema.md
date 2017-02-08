OSiRIS LDAP Topology & Schema
=============================

This document defines the topology of and strategic use of attributes and object classes for our centralized, but multi-master replicated OSiRIS LDAP service.

## Topology

OSiRIS' LDAP Instance will begin at the Base DN of `dc=osris, dc=org`.

I propose that:
 * We put people in `ou=People, dc=osris, dc=org` and link them to their `eduOrg` as defined by the `eduOrg` objectClass before.
 * We put *organizations* in `ou=Organizations, dc=osris, dc=org`, and make sure they confirm to `eduOrg`.  OSiRIS itself should be sucn an `eduOrg`, as some *automata* and *people* will only have affiliation to the OSiRIS organization.
 * We should put system daemon accounts, and accounts we use for scripting into `ou=Automata, dc=osris, dc=org`, these too can have an affiliation, but many will only be affiliated with the OSiRIS Organization.

We collapse all attributes required for `Organizations`, `People`, and `Automata` into one objectClass for each entry type.  These object classes will apply to *all* entries of this type.  So objectClasses such as `posixUser` and `posixGroup` should remain independently assigned, all **People** may not be `posixUser`s, after all.  But we shouldn't have to add the entire `inetOrgPerson` objectClass to only assign the `mail` attribute to the entry, instead we'll allow `osirisPerson` entries to have the `mail` attribute.

We should do the same for `osirisGroup`, allowing for all of the existing attributes `member`, `memberOf`, etc, and extending it with our own attributes as needed.

This approach serves 2 purposes.
 1. It doesn't allow us to add attributes to entries that we haven't considered appropriate.
 2. It documents what attributes we expect to see in our entries.

## LDIF Examples

### Organization
```ldif
    dn: cn=Wayne State University, ou=Organizations, dc=osris, dc=org
    objectClass: top
    objectClass: osirisOrganization
    objectClass: osirisEntity
    cn: Wayne State University
    description: A premier research university serving a diverse body of motivated students in vibrant Midtown, the cultural center of Detroit.
    eduOrgHomePageURI: https://wayne.edu
    eduOrgIdentityAuthNPolicyURI: https://computing.wayne.edu/accessid/
    eduOrgWhitePagesURI: https://wayne.edu/people/
    l: Detroit
    mailAccessDomain: wayne.edu
    o: Wayne State University
    postalCode: 48202
    postalAddress: Wayne State University$42. W. Warren Ave.$Detroit, MI 48202
    st: MI
    telephoneNumber: +1 313 577 2424
```

### Person
```ldif
    dn: eppn=ak1520@wayne.edu, ou=People, dc=osris, dc=org
    objectClass: top
    objectClass: osirisEntity
    objectClass: osirisPerson
    objectClass: posixUser
    cn: Michael Gregorowicz
    eduPersonOrgDN: cn=Wayne State University, ou=Organizations, dc=osris, dc=org
    eduPersonPrincipalName: ak1520@wayne.edu
    eduPersonScopedAffiliation: employee@wayne.edu
    eduPersonScopedAffiliation: member@wayne.edu
    eduPersonScopedAffiliation: student@wayne.edu
    givenName: Michael
    mail: michael.gregorowicz@wayne.edu
    sn: Gregorowicz
    uid: ak1520@wayne.edu
```

## Object Classes We Should Make Use Of

I'll spare us several of the core objectClasses, we'll be using `top`, `person`, `organizationalPerson`, `organizationalUnit`, `groupOfNames`, `groupOfUniqueNames`, `posixAccount`, `posixGroup`, and `inetOrgPerson`.  We'll use our own objectClasses including but not limited to `osirisPerson`, `osirisEntity`, `osirisAutomaton`, `osirisOrganization`, `osirisResourceProvider`, `osirisCentralAuthority`, and `osirisGroup`.  Additionally, we'll use any and all attributes required for the proper functioning of COmanage, but the goal will be to get *it* to conform to *us* and not the other way around.

*Note:* All attributes are denoted in the subjectively easier-to-read OpenLDAP schema format.  They will all be converted to ns-slapd compatible schemas by a script I wrote (and will hopefully find soon), or will rewrite again.  Years ago I had written a set of scripts that converted the schema to / from these formats but cannot find it now.  That said, I do remember them being very easy scripts to write.

### eduPerson Object Classes
```ldif
objectclasses: ( 1.3.6.1.4.1.5923.1.1.2
    NAME 'eduPerson'
    AUXILIARY
    MAY ( 
        eduPersonAffiliation $ eduPersonNickname $
        eduPersonOrgDN $ eduPersonOrgUnitDN $
        eduPersonPrimaryAffiliation $ eduPersonPrincipalName $
        eduPersonEntitlement $ eduPersonPrimaryOrgUnitDN $
        eduPersonScopedAffiliation
    )
)
```

### OSiRIS Object Classes
```ldif
objectClass ( 1.3.5.1.3.1.17128.313.1 
    NAME 'osirisEntity' SUP top STRUCTURAL 
    MUST ( osirisEntityUniqueID ) 
    MAY ( osirisKeyThumbprint $ cn $ osirisEncryptionCertificate $ osirisSigningCertificate $ description ) )

objectClass ( 1.3.5.1.3.1.17128.313.2 
    NAME 'osirisResourceProvider' SUP osirisEntity AUXILIARY 
    MUST ( osirisKeyThumbprint $ osirisSigningCertificate $ osirisEncryptionCertificate $ osirisStpEndpoint ) )

objectClass ( 1.3.5.1.3.1.17128.313.3 
    NAME 'osirisCentralAuthority' SUP top AUXILIARY 
    MUST ( osirisKeyThumbprint $ osirisOakEndpoint $ osirisSigningCertificate $ osirisEncryptionCertificate ) )
    
objectClass ( 1.3.5.1.3.1.17128.313.4 
    DESC 'groups of osirisEntity objects'
    NAME 'osirisGroup' SUP groupOfNames STRUCTURAL 
    MUST ( osirisEntityUniqueID ) 
    MAY ( description ) )
```

### eduOrg Object Classes
```ldif
objectclasses: ( 1.3.6.1.4.1.5923.1.2.2
    NAME 'eduOrg'
    AUXILIARY
    MAY ( 
        cn $ eduOrgHomePageURI $
        eduOrgIdentityAuthNPolicyURI $ eduOrgLegalName $
        eduOrgSuperiorURI $ eduOrgWhitePagesURI $
    )
)
```

## Attributes We Should Make Use Of

### Attributes from Core Schemas
```ldif
attributeType ( 2.5.4.49 
    NAME ( 'dn' 'distinguishedName' ) 
    DESC 'Standard LDAP attribute type' 
    SYNTAX 1.3.6.1.4.1.1466.115.121.1.12 
    X-ORIGIN 'RFC 2256' 
)

attributeType ( 2.5.4.3 
    NAME ( 'cn' 'commonName' ) 
    DESC 'Standard LDAP attribute type' 
    SUP name 
    X-ORIGIN 'RFC 2256' 
)

attributeType ( 2.5.4.4 
    NAME ( 'sn' 'surName' ) 
    DESC 'Standard LDAP attribute type' 
    SUP name
    X-ORIGIN 'RFC 2256' 
)

attributeType ( 2.5.4.12 
    NAME 'title' 
    DESC 'Standard LDAP attribute type' 
    SUP name 
    X-ORIGIN 'RFC 2256' 
)

attributeType ( 2.16.840.1.113730.3.1.241 
    NAME 'displayName' 
    DESC 'inetOrgPerson attribute type' 
    SYNTAX 1.3.6.1.4.1.1466.115.121.1.15 
    SINGLE-VALUE 
    X-ORIGIN 'inetOrgPerson Internet Draft' 
)

```

### eduPerson Attributes
```ldif
attributeType ( 1.3.6.1.4.1.5923.1.1.1.1
    NAME 'eduPersonAffiliation'
    DESC 'eduPerson per Internet2 and EDUCAUSE'
    EQUALITY caseIgnoreMatch
    SYNTAX '1.3.6.1.4.1.1466.115.121.1.15' 
)
attributeType ( 1.3.6.1.4.1.5923.1.1.1.2
    NAME 'eduPersonNickname'
    DESC 'eduPerson per Internet2 and EDUCAUSE'
    EQUALITY caseIgnoreMatch
    SYNTAX '1.3.6.1.4.1.1466.115.121.1.15' 
)
attributeType ( 1.3.6.1.4.1.5923.1.1.1.3
    NAME 'eduPersonOrgDN'
    DESC 'eduPerson per Internet2 and EDUCAUSE'
    EQUALITY distinguishedNameMatch
    SYNTAX '1.3.6.1.4.1.1466.115.121.1.12' SINGLE-VALUE 
)
attributeType ( 1.3.6.1.4.1.5923.1.1.1.4
    NAME 'eduPersonOrgUnitDN'
    DESC 'eduPerson per Internet2 and EDUCAUSE'
    EQUALITY distinguishedNameMatch
    SYNTAX '1.3.6.1.4.1.1466.115.121.1.12' 
)
attributeType ( 1.3.6.1.4.1.5923.1.1.1.5
    NAME 'eduPersonPrimaryAffiliation'
    DESC 'eduPerson per Internet2 and EDUCAUSE'
    EQUALITY caseIgnoreMatch
    SYNTAX '1.3.6.1.4.1.1466.115.121.1.15' SINGLE-VALUE 
)
attributeType ( 1.3.6.1.4.1.5923.1.1.1.6
    NAME 'eduPersonPrincipalName'
    DESC 'eduPerson per Internet2 and EDUCAUSE'
    EQUALITY caseIgnoreMatch
    SYNTAX '1.3.6.1.4.1.1466.115.121.1.15' SINGLE-VALUE 
)
attributeType ( 1.3.6.1.4.1.5923.1.1.1.7
    NAME 'eduPersonEntitlement'
    DESC 'eduPerson per Internet2 and EDUCAUSE'
    EQUALITY caseIgnoreMatch
    SYNTAX '1.3.6.1.4.1.1466.115.121.1.15' 
)
attributeType ( 1.3.6.1.4.1.5923.1.1.1.8
    NAME 'eduPersonPrimaryOrgUnitDN'
    DESC 'eduPerson per Internet2 and EDUCAUSE'
    EQUALITY distinguishedNameMatch
    SYNTAX '1.3.6.1.4.1.1466.115.121.1.12' 
    SINGLE-VALUE
)
attributeType ( 1.3.6.1.4.1.5923.1.1.1.9
    NAME 'eduPersonScopedAffiliation'
    DESC 'eduPerson per Internet2 and EDUCAUSE'
    EQUALITY caseIgnoreMatch
    SYNTAX '1.3.6.1.4.1.1466.115.121.1.15' 
) 
```

### OSiRIS Attributes
```ldif
attributeType ( 1.3.5.1.3.1.17128.313.1.1
    NAME 'osirisKeyThumbprint',
    DESC 'a Base64-URL encoded SHA256 hash of the DER encoded RSA signing public key'
    EQUALITY caseExactMatch
    SINGLE_VALUE
    SYNTAX 1.3.6.1.4.1.1466.115.121.1.40 )

attributeType (1.3.5.1.3.1.17128.313.1.2
    NAME 'osirisEntityUniqueID'
    DESC 'a UUID uniquely identifying an OSiRIS entity'
    EQUALITY caseIgnoreMatch
    SINGLE_VALUE
    SYNTAX 1.3.6.1.4.1.1466.115.121.1.40 )

attributeType (1.3.5.1.3.1.17128.313.1.3
    NAME 'osirisOakEndpoint'
    DESC 'full URL of the OAK (OAA keyring service) endpoint'
    EQUALITY caseIgnoreMatch
    SINGLE_VALUE
    SYNTAX 1.3.6.1.4.1.1466.115.121.1.40 )

attributeType (1.3.5.1.3.1.17128.313.1.4
    NAME 'osirisStpEndpoint'
    DESC 'full URL of the STP (OAA to native gateway service) endpoint'
    EQUALITY caseIgnoreMatch
    SINGLE_VALUE
    SYNTAX 1.3.6.1.4.1.1466.115.121.1.40 )

attributeType (1.3.5.1.3.1.17128.313.1.5
    NAME 'osirisEncryptionCertificate'
    DESC 'a DER encoded encryption certificate'
    EQUALITY caseExactMatch
    SINGLE_VALUE
    SYNTAX 1.3.6.1.4.1.1466.115.121.1.40 )

attributeType (1.3.5.1.3.1.17128.313.1.6
    NAME 'osirisSigningCertificate'
    DESC 'a DER encoded signing certificate'
    EQUALITY caseExactMatch
    SINGLE_VALUE
    SYNTAX 1.3.6.1.4.1.1466.115.121.1.40 )

attributeType (1.3.5.1.3.1.17128.313.1.7
    NAME 'osirisAccessTokens'
    DESC 'an entitys current set of issued osirisAccessTokens'
    EQUALITY caseExactMatch
    MULTI_VALUE
    SYNTAX 1.3.6.1.4.1.1466.115.121.1.40 )

attributeType (1.3.5.1.3.1.17128.313.1.8
    NAME 'osirisPreviousEncryptionCertificates'
    DESC 'all historical DER encoded encryption certificates for this entity'
    EQUALITY caseExactMatch
    MULTI_VALUE
    SYNTAX 1.3.6.1.4.1.1466.115.121.1.40 )

attributeType (1.3.5.1.3.1.17128.313.1.9
    NAME 'osirisPreviousSigningCertificates'
    DESC 'all historical DER encoded signing certificates for this entity'
    EQUALITY caseExactMatch
    MULTI_VALUE
    SYNTAX 1.3.6.1.4.1.1466.115.121.1.40 )
```

### Attributes From eduOrg Schema
```ldif
attributeType ( 1.3.6.1.4.1.5923.1.2.1.2
    NAME 'eduOrgHomePageURI'
    DESC 'eduOrg per Internet2 and EDUCAUSE'
    EQUALITY caseExactIA5Match
    SYNTAX '1.3.6.1.4.1.1466.115.121.1.15' 
)
attributeType ( 1.3.6.1.4.1.5923.1.2.1.3
    NAME 'eduOrgIdentityAuthNPolicyURI'
    DESC 'eduOrg per Internet2 and EDUCAUSE'
    EQUALITY caseExactIA5Match
    SYNTAX '1.3.6.1.4.1.1466.115.121.1.15' 
)
attributeType ( 1.3.6.1.4.1.5923.1.2.1.4
    NAME 'eduOrgLegalName'
    DESC 'eduOrg per Internet2 and EDUCAUSE'
    EQUALITY caseIgnoreMatch
    SYNTAX '1.3.6.1.4.1.1466.115.121.1.15' 
)
attributeType ( 1.3.6.1.4.1.5923.1.2.1.5
    NAME 'eduOrgSuperiorURI'
    DESC 'eduOrg per Internet2 and EDUCAUSE'
    EQUALITY caseExactIA5Match
    SYNTAX '1.3.6.1.4.1.1466.115.121.1.15' 
)
attributeType ( 1.3.6.1.4.1.5923.1.2.1.6
    NAME 'eduOrgWhitePagesURI'
    DESC 'eduOrg per Internet2 and EDUCAUSE'
    EQUALITY caseExactIA5Match
    SYNTAX '1.3.6.1.4.1.1466.115.121.1.15' 
)
```

