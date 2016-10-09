# OSiRIS Access Assertions

## Glossary

* Central Authority - A Service that:
 * Maintains a database of registered _Resource Providers_
 * Interfaces with identity providers to authenticate _Resource Users_
 * Facilitates matchmaking / pairing up of _Resource Users_ with _Resource Providers_
 * Allows the formation of roles and groups for convenience 
 * Facilitates the safe keeping of Access Assertions (OAAs) long term
* Resource User - An individual or group of individuals that wants to have or currently has access to a resource pvoided by a _Resource Provider_
* Resource Provider - A system capable of providing certain types of services to _Resource User_s. 

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

* _Central Authority_ - e.g. OSiRIS `oakd`, trusts InCommon and other IdPs, handles Authentication and authorization for the OSiRIS enterprise itself, and performs some AuthZ.  If `oakd` issues an 

* _Resource Authorities/Providers_ - e.g. OSiRIS `stpd`, has certificates and will sign tokens issued by _Identity Authorities_ if certain criteria are met.  This gives resource owners a bit of their own AuthZ power and might come in handy.  This also introduces a point in the OAA issuance flow for provisioning of resources themselves.  Even if access keys are ephemeral, the resources themselves (UNIX Accounts, sudo rights, filesystems, namespaces, and block devices) are not.

## LDAP Schema (utilize oid urns below)

```
attributeType ( 1.3.5.1.3.1.17128.313.1.1
    NAME 'osirisKeyThumbprint',
    DESC 'a Base64-URL encoded SHA256 hash of a DER encoded certificate'
    EQUALITY caseExactMatch
    SINGLE_VALUE
    SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )

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

## OAA Issuance Flow

### Access Request

```
{
    "iss": "urn:oid:1.3.5.1.3.1.17128.313.1.1:SGvZyx1ziKvnNr7_q8OrBGauJUm4dIa",
    "jti": "E821240C-5494-4B40-8387-5DC3A3B37813",
    "iat": 1473280947,
    "exp": 1473280977,
    "sub": ["ak1520@wayne.edu", "urn:1.3.5.1.3.1.17128.313.1.1:SGvZyx1ziKvnNr7_q8OrBGauJUm4dIa:comanage:1"],
    "aud": [
        "urn:oid:1.3.5.1.3.1.17128.313.1.1:AfRlV67YnPf-Q-8WpM23B7Ds7vlIJJER", "urn:oid:1.3.5.1.3.1.17128.313.1.1:hRiHEh-3fCe47Kg0UhMVjx1RRYVsdqDk"
    ],

    // session key encrypted with each resource provider's public key
    // provided in the same order they are listed in 'aud', any sensitive
    // data will be encrypted with this symmetric session key using
    // crypto_stream_xor
    "sk": [
        "vr77Lv31xJXQPR0pNA63JC4",
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
    access: [
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
