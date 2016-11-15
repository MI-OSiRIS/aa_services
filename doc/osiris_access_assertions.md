# OSiRIS Access Assertions

## Glossary

* Central Authority - A Service that:
 * Maintains a database of registered _Resource Providers_
 * Interfaces with identity providers to authenticate _Resource Users_
 * Facilitates matchmaking / pairing up of _Resource Users_ with _Resource Providers_
 * Allows the formation of roles and groups for convenience 
 * Facilitates the safe keeping of Access Assertions (OAAs) long term
* Resource User - An individual or group of individuals that wants to have or currently has access to a resource pvoided by a _Resource Provider_
* Resource Provider - A system capable of providing certain types of services to _Resource Users_. 

* OSiRIS Token Types
 * _OSiRIS Access Request (OAR)_ - Issued by _Central Authority_ `oakd` to one or more _Resource Authorities_ `stpd` to provision services and receive an...
 * _OSiRIS Access Grant (OAG)_ - Issued by _Resource Authorities_ `stpd` to the _Central Authority_ `oakd` to be included in an...
 * _OSiRIS Access Assertion (OAA)_ - To be stored by _Central Authority_ `oakd` and delivered to user agents as part of an..
 * _OSiRIS Access Token (OAT)_ (short lived, hours/days/weeks) and / or an _OSiRIS Refresh Token (ORT)_ (longer-lived, months/years) which are stored on client machines and are used as bearer tokens to gain access to resources

## Novel benefits of the OAA approach

* Allows for the eventual removal of a central authority (some kind of auction service or matchmaking service may be required, but a variety of these may exist)
* Resource providers may set their own terms for resources allocated by them
* Allows codification of many different types of access
* Doesn't require a RDBMs or complicated database schema to know who is who, and who gets access to what.  Everything any participating system or user needs to know is codified within the bearer token and accessible only by the parties that have the encryption keys for the fragments.

## Authority Types

* _Identity Authority_ - A traditional SAML2, OpenID Connect, CAS, or to-be-created assertion generating authority for a given entity.

* _Central Authority_ - e.g. OSiRIS `oakd`, trusts InCommon and other IdPs, handles Authentication and authorization for the OSiRIS enterprise itself, and performs some AuthZ.  `oakd` issues _OARs_ and _OAAs_ on behalf of authenticated principals.

* _Resource Authorities/Providers_ - e.g. OSiRIS `stpd`, has certificates and will sign tokens issued by _Identity Authorities_ if certain criteria are met.  This gives resource owners a bit of their own AuthZ power and might come in handy.  This also introduces a point in the OAA issuance flow for provisioning of resources themselves.  Even if access keys are ephemeral, the resources themselves (UNIX Accounts, sudo rights, filesystems, namespaces, and block devices) are not.

## LDAP Schema (utilize oid urns below)

```
attributeType ( 1.3.5.1.3.1.17128.313.1.1
    NAME 'osirisKeyThumbprint',
    DESC 'a Base64-URL encoded SHA256 hash of a DER encoded RSA public key'
    EQUALITY caseExactMatch
    SINGLE_VALUE
    SYNTAX 1.3.6.1.4.1.1466.115.121.1.40 )

attributeType (1.3.5.1.3.1.17128.313.1.2
    NAME 'osirisEntityUniqueID'
    DESC 'a UUID uniquely identifying an OSiRIS entity'
    EQUALITY caseIgnoreMatch
    SINGLE_VALUE
    SYNTAX 1.3.6.1.4.1.1466.115.121.1.40 )

objectClass ( 1.3.5.1.3.1.17128.313.1 
    NAME 'osirisEntity' SUP top AUXILIARY 
    MAY ( osirisKeyThumbprint ) )

objectClass ( 1.3.5.1.3.1.17128.313.2 
    NAME 'osirisResourceProvider' SUP top AUXILIARY 
    MUST ( osirisKeyThumbprint ) )

objectClass ( 1.3.5.1.3.1.17128.313.3 
    NAME 'osirisCentralAuthority' SUP top AUXILIARY 
    MUST ( osirisKeyThumbprint ) )

```

## Pre-Registration

### Central Authority Metadata (for OAR, OAG, and OAA)

The `Central Authority` will need metadata of its own, note the `urn:oid` format used here is based upon the LDAP schema defined above for the `osirisKeyThumbprint` attribute.  **Please Note** The EntityID/Issuer string format is the `urn:oid:1.3.5.1.3.1.17128.313.1.1:` prefix followed by the [jwk thumbprint](https://tools.ietf.org/html/rfc7638) of the current _signing_ key.  Safeguards are in place, for example calling `osiris_key_thumbprint` on an encryption certificate object will throw a fatal error.  A more durable way to keep track of issuers may be a randomly generated UUID/common name for the `Central Authority` or the `Resource Authority`, which could be represented as `urn:oid:1.3.5.1.3.1.17128.313.1.2:UUID`, or `urn:uuid:UUID` 

```
{
    "issuer": "urn:oid:1.3.5.1.3.1.17128.313.1.2:4A3348F3-40F7-4923-8D42-65666C6592A8",
    // or optionally
    // "issuer": "urn:uuid:4A3348F3-40F7-4923-8D42-65666C6592A8",
    "grant_endpoint": "https://comanage.osris.org/oakd/oag/",
    "token_endpoint": "https://comanage.osris.org/oakd/oat/",
    "jwks_uri": "https://comanage.osris.org/oakd/jwks.json",
    // or optionally, inline with the metadata
    "jwks": [
        {
            "use": "enc",
            "e": "AQAB",
            "kty": "RSA",
            "n": "0T1hsZvkMoV2RC0xKAU1cNTZjZFoF0e93KZ33E-WVuzR6O2lJHaVo4puYEw4r5L8t5pIFEnfVM..."
        },
        {
            "use": "sig",
            "e": "AQAB",
            "kty": "RSA",
            "n":"59qvRCIb8ggFrn-lp1g32841Q8764jd3uOwUHrA-apWpI5XYDwdE-6GIoM3gSKxXrNXsWz1Qcvm..."
        }
    ],
}
```

### Resource Provider Metadata

All Resource Providers need to register themselves with the central authority, in the spirit of SAML2
or OpenID metadata something along the lines of:

```
{
    "issuer": "urn:oid:1.3.5.1.3.1.17128.313.1.1:42tmeP_0-ZmskjspWJYrUNPa1x9kHvRDY09ZDNssB0c",
    "request_endpoint": "https://stpd-01.wsu.osris.org:8181/oar/",
    "token_endpoint": "https://stpd-01.wsu.osris.org:8181/oat/",
    "jwks_uri": "https://stpd-01.wsu.osris.org:8181/jwks.json",
    // or optionally, inline with the metadata
    "jwks": [
        {
            "use": "enc",
            "e": "AQAB",
            "kty": "RSA",
            "n": "0T1hsZvkMoV2RC0xKAU1cNTZjZFoF0e93KZ33E-WVuzR6O2lJHaVo4puYEw4r5L8t5pIFEnfVM..."
        },
        {
            "use": "sig",
            "e": "AQAB",
            "kty": "RSA",
            "n":"59qvRCIb8ggFrn-lp1g32841Q8764jd3uOwUHrA-apWpI5XYDwdE-6GIoM3gSKxXrNXsWz1Qcvm..."
        }
    ],
    // provide a list of services provided by this RP.. (can be scoped, so the CA can route the
    // request appropriately, or unscoped and OARs can be refused if the RP refuses to provide for
    // the subject's origin/scope)
    "provides": ["ceph.*@wayne.edu", "ceph.*@umich.edu", "ceph.*@msu.edu", "ceph.s3.read@emich.edu"],
}
```

## OAA Issuance Flow

### JWT-like header segments

The header should state the type of token this is, using `OAR` for Access Requests, `OAG` for Access Grants,
`OAA` for Access Assertions, and `JWT` for OAT and ORT for compatibility reasons.

```
{
    "typ": "OAR",
    "alg": "RS256"
}
```

### Access Request

```
{
    "iss": "urn:oid:1.3.5.1.3.1.17128.313.1.1:adYu1swU1C0gMV12mYOwDKUjn1VQ4nndRv35bBEx-wM",
    "jti": "E821240C-5494-4B40-8387-5DC3A3B37813",
    "iat": 1473280947,
    "exp": 1473280977,
    "sub": [
        "ak1520@wayne.edu", 
        "urn:oid:1.3.5.1.3.1.17128.313.1.1:adYu1swU1C0gMV12mYOwDKUjn1VQ4nndRv35bBEx-wM:co:1:role:3"
    ],
    "aud": [
        "urn:oid:1.3.5.1.3.1.17128.313.1.1:8h-A8A72BLO8yjZjdafO860In5WIeTQQhwb1A1VyeSw", "urn:oid:1.3.5.1.3.1.17128.313.1.1:tQoTGHJ-tlWkpDQ0X88RyDP52Xe-KCQhNUW_8LuEMEY",
        "urn:oid:1.3.5.1.3.1.17128.313.1.1:gwOWVIf26Htah1Yovtr3_oFov4LfEt7c10nUozGghug"
    ],

    // session key encrypted with each resource provider's public key
    // provided in the same order they are listed in 'aud', any sensitive
    // data will be encrypted with this symmetric session key using
    // crypto_secret_box

    // the session key is encypted with SHA256 RSA-OAEP once for every audience
    // if a particular audience member is to be excluded from being able to 
    // decrypt "_opaque" content for this assertion, a 'null' will be included
    // in the index that corresponds to its index in the 'aud' array.  notice
    // the second audience member 'hRiHEh-3fCe47Kg0UhMVjx1RRYVsdqDk' will be
    // unable to decrypt any opaque content in this message
    "sk": [
        "vr77Lv31xJXQPR0pNA63JC4",
        null,
        "/02ZGeOePwriwiO6F3r4eok"
    ],

    // at any level an "_opaque" property may occur.  it is to be base64url
    // decoded, and decrypted with the session key, and its properties are 
    // to be merged into the resulting object structure in the place where
    // it is found 
    // note: the first 24 bytes after decoding are the nonce.
    // for example:
    "_opaque": "zOkEBma9l/8xx8bkH2CE5LAXpq75tguJfVSRYH9tZ3I6vn9OJAnCLoh0ehF",

    // an array of access we're requesting.  order corresponds to the
    // 'resources' array below, here we request 'read' access to ceph
    // filesystems science1:/some/science, and sci45:/more/science. 
    // 'read', 'write', and 'admin' access to 'science2:/mad/science' 
    // and shell accounts and access to 'science.example.com' and
    // 'shells.archimedes.gr'
    "access": [
        // literal strings represent single types of access, could also be
        // written as ["read"],
        "read",

        // arrays represent multiple types of access
        ["read", "write", "admin"],

        // but if the 'access' is an object instead of a string or array, 
        // consider it 'advanced', and include extra information to facilitate
        // the grant
        {
            // the label is what we call this access (required)
            "label": "shell-account",

            // if present it means only these RPs should consider this but
            // say we know these resources offer shell accounts
            // portion of the OAR (optional)
            "aud": ["urn:oid:1.3.5.1.3.1.17128.313.1.1:hRiHEh-3fCe47Kg0UhMVjx1RRYVsdqDk"],
            
            // preflight run to see if resource has been provisioned, if this 
            // code returns 1, then run "grant", if this code returns 0 then
            // run "prov", if this code returns -1 then run "dprov" (required)
            "pchk": ["1+CeZgfwM5DdboGVlrHmK3rashzaLiJf4h7YdlVkdDo6FM0jT4l4K"],
            
            // what to run to provision access (optional)
            // e.g. this code could useradd 
            "prov": "[zaURai/rvr77Lv31xJXQPR0pNA63JC4am0FS8/gimfv+1LcV"],
            
            // what to run to deprovision resource (optional)
            // e.g. this code could tar up a home dir, userdel -r, and email
            // the user that they have 30 days to download it
            "dprov": "[zaURai/rvr77Lv31xJXQPR0pNA63JC4am0FS8/gimfv+1LcV"],
            
            // what to run to grant ephemeral access to the resource or to
            // actually perform the action defined by this label (optional)
            // e.g. this code could email the user a temp password
            "grant": ["zaURai/rvr77Lv31xJXQPR0pNA63JC4am0FS8/gimfv+1LcV"],

            // what to run to revoke ephemeral access to the resource or to
            // actually undo the action defined by this label (optional)
            "revoke": ["rvr77Lv31xJXQPR0pNA63JC4am0FS8"],

            // requested provision expiration time (dprov runs after this time,
            // optional, defaults to the heat death of the universe)
            "pexp": 1504816977,

            // requested grant expiration time (ephemeral access is removed
            // after this time, optional, defaults to iat + (86400 * 7))
            "gexp": 1473885747
        }
    ],

    resources: [
        // as with "access" above, arrays list multiple resources
        ['science1:/some/science', 'sci45:/more/science'],

        // string literals list single resources
        'science2:/mad/science',
        [
            // and objects denote more "complex" data
            {
                "host": "science.example.com",
                "requested_userid": "ak1520",
                "ssh_pubkey": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3+iRTnUqdbCgiXY3rbVbVXR1r1RbZE/z3Pfxb6M/qz ak1520@example.edu"
            },
            {
                "host": "shells.archimedes.gr",
                "requested_userid": "ak1520",
                "ssh_pubkey": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3+iRTnUqdbCgiXY3rbVbVXR1r1RbZE/z3Pfxb6M/qz ak1520@example.edu"
            }
        ]
    ]
}
```

### Access Grant

The grant contains specifics about what the _Resource Provider_ did to facilitate the OAR, it will also
explicitly point out what parts of the OAR it refused or had problems facilitating.  For security purposes
the OAG should encrypt sensitive information it needs for itself with a symmetric key known only to itself.

A new symmetric key should be created for every OAG ID and stored in a local database of keys until the OAG
itself expires.  _OAG_s may be renewed / refreshed as part of the refresh process done in an _ORT_, therefore
expiry times on _OAG_s should be slightly longer than the refresh time of _ORT_s, else the deprovision actions
and/or the removal of session encryption key happens before the user has a chance to refresh their _OAG_.

This puts expiry time frames for OAGs in the "months/years" range, but none the less they should eventually 
expire.

```
{
    "iss": "urn:oid:1.3.5.1.3.1.17128.313.1.1:hRiHEh-3fCe47Kg0UhMVjx1RRYVsdqDk",
    "iat": 1473280957,
    "exp": 1567888957,
    "sub": ["ak1520@wayne.edu", "urn:1.3.5.1.3.1.17128.313.1.1:SGvZyx1ziKvnNr7_q8OrBGauJUm4dIa:comanage:1"],
    "jti": "51679296-37B9-45BE-BE25-A371CF27E5D2",


}
```
