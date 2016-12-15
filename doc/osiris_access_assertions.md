# OSiRIS Access Assertions

## Glossary

* **Central Authority** - A Service that:
 * Maintains a database of registered _Resource Providers_
 * Interfaces with identity providers to authenticate _Resource Users_
 * Facilitates matchmaking / pairing up of _Resource Users_ with _Resource Providers_
 * Allows the formation of roles and groups for convenience 
 * Facilitates the safe keeping of Access Assertions (OAAs) long term
* **Resource Requestor** - An individual or group of individuals wanting to have resources provisioned that do not already exist
* **Resource User** - An individual or group of individuals that wants to have or currently has access to a resource provided by a _Resource Provider_
* **Resource Provider** - A system capable of providing certain types of services to _Resource Requestors_ and _Resource Users_. 
* **Resource Owner** - An individual or group of individuals who requested resources be provisioned, and subsequently had that request granted

* OSiRIS Token Types
 * _OSiRIS Access Request (OAR)_ - Issued by _Central Authority_ `oakd` to one or more _Resource Authorities_ `stpd` to provision services and receive an...
 * _OSiRIS Access Grant (OAG)_ - Issued by _Resource Authorities_ `stpd` to the _Central Authority_ `oakd` to be included in an...
 * _OSiRIS Access Assertion (OAA)_ - To be stored by _Central Authority_ `oakd` and delivered to user agents as part of an..
 * _OSiRIS Access Token (OAT)_ - (short lived, hours/days/weeks) and / or an 
 * _OSiRIS Refresh Token (ORT)_ - (longer-lived, months/years) which are stored on client machines and are used as bearer tokens to gain access to resources via `stpd`

## Novel benefits of the OAA approach

* Allows for the eventual removal of a central authority (some kind of auction service or matchmaking service may be required, but a variety of these may exist)
* Resource providers may set their own terms for resources allocated by them
* Allows codification of many different types of access
* Doesn't require a RDBMs or complicated database schema to know who is who, and who gets access to what.  Everything any participating system or user needs to know is codified within the bearer token and accessible only by the parties that have the encryption keys for the fragments.
* Fine-grained control over service level expectations
 * Run of the mill availability levels e.g. 99.99% uptime
 * Well definined minimum service levels say "100Mbps guaranteed from disk on Network A to Network B"
 * Well defined penalties, fees, or refunds in the event that service levels are not maintained, 99.98% availablility = 10% refund

## Authority Types

* _Identity Authority_ - A traditional SAML2, OpenID Connect, CAS, or to-be-created assertion generating authority for a given entity.

* _Central Authority_ - e.g. OSiRIS `oakd`, trusts InCommon and other IdPs, handles Authentication and authorization for the OSiRIS enterprise itself, and performs some AuthZ.  `oakd` issues _OARs_ and _OAAs_ on behalf of authenticated principals.

* _Resource Authorities/Providers_ - e.g. OSiRIS `stpd`, has certificates and will sign tokens issued by _Identity Authorities_ if certain criteria are met.  This gives resource owners a bit of their own AuthZ power and might come in handy.  This also introduces a point in the OAA issuance flow for provisioning of resources themselves.  Even if access keys are ephemeral, the resources themselves (UNIX Accounts, sudo rights, filesystems, namespaces, and block devices) are not.

## LDAP Schema (utilize oid urns below)

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
    "issuer": "urn:uuid:4A3348F3-40F7-4923-8D42-65666C6592A8",
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
    "iss": "urn:uuid:58F1C380-FC8F-4D1E-8C5B-0FC32F81087D",
    "jti": "E821240C-5494-4B40-8387-5DC3A3B37813",
    "iat": 1473280947,
    "exp": 1473280977,
    "sub": [
        // a named individual subject
        "ak1520@wayne.edu",
        
        // an osirisEntityUniqueID matching a comanage group within a CO
        "urn:oid:1.3.5.1.3.1.17128.313.1.2:85B68BF3-2343-42FF-A0C4-C10E1C3CA868"
    ],
    
    // the resource providers that this request is for
    "aud": [
        "urn:uuid:6D522874-F79E-4577-8EFF-414CF6895065", 
        "urn:uuid:910848D6-17B1-4C46-9AD7-B397C7C9539E",
        "urn:uuid:F07FB237-7A49-49AA-BDCE-96890E69A637"
    ],

    // session key encrypted with each resource provider's public key
    // provided in the same order they are listed in 'aud', any sensitive
    // data will be encrypted with this symmetric session key using
    // crypto_secret_box

    // the session key is encypted with SHA256 RSA-OAEP once for every audience
    // if a particular audience member is to be excluded from being able to 
    // decrypt "_opaque" content for this assertion, a 'null' will be included
    // in the index that corresponds to its index in the 'aud' array.  notice
    // the second audience member '910848D6-17B1-4C46-9AD7-B397C7C9539E' will be
    // unable to decrypt any opaque content in this message
    "_sk": [
        "vr77Lv31xJXQPR0pNA63JC4",
        null,
        "/02ZGeOePwriwiO6F3r4eok"
    ],

    // within any object an "_opaque" property may occur.  it is to be base64url
    // decoded, and decrypted with the session key, and its properties are 
    // to be merged into the resulting object structure in the place where
    // it is found.  _opaque properties that are simple strings may be read
    // by all audience members using a simple session key.
    
    // note: the first 24 bytes after decoding are the nonce.
    // for example:
    "_opaque": "zOkEBma9l/8xx8bkH2CE5LAXpq75tguJfVSRYH9tZ3I6vn9OJAnCLoh0ehF",

    // an array of access we're requesting.  order corresponds to the
    // 'resources' array below, here we request 'read' access to ceph
    // filesystems science1:/some/science, and sci45:/more/science. 
    // 'read', 'write', and 'admin' access to 'science2:/mad/science' 
    // and shell accounts and access to 'science.example.com' and
    // 'shells.archimedes.gr'
    "requested_access": {
        
        
        "access": [
            // literal strings represent single kinds of access, could also be
            // written as ["read"],
            {
                "type": "cephfs-mount",
                "kind": "read",
                
                // resources can be lists of strings.  these resources already exist and we
                // do have the requisite affiliations / attributes for the read access requested
                "resource": ['science1:/some/science', 'sci45:/more/science']
            },

            // arrays represent multiple types of access
            {
                "type": "cephfs-mount",
                "kind": ["read", "write", "admin"],
                
                // resources can be plain strings, this resource already exists but we don't
                // have the requisite attributes for admin access, just read and write
                "resource": "science2:/mad/science"
            },

            // we are provisioning these resources below but we also want to request access to them
            {
                "type": "shell-account",
                "kind": ["login", "sudo"],                
                "resource": "ssh://ak1520@shells.archimedes.gr"
            },

            {
                "type": "shell-account",
                "kind": ["login", "sudo"],
                "resource": "ssh://ak1520@science.example.com"
            }            

        ],
        
        provision: [
            // but if the 'access' is an object instead of a string or array, 
            // consider it 'advanced', and include extra information to facilitate
            // the grant.  here we're requesting to provision service that doesn't
            // exist yet.  science.example.com does not offer shell accounts but
            // shells.archimedes.gr does.  we also have the requisite affiliations
            // and approvals to obtain a shell account on shells.archimedes.gr
            {
                // the type is what we call this resource (required)
                "type": "shell-account",

                // kinds of access users can have to this resource
                "kind": ["login", "sudo"],

                "resource": [
                    // objects denote more "complex" data
                    {
                        // common name will be used in the future when people request access to this resource
                        "common_name": "ssh://ak1520@science.example.com",
                        
                        // the rest is configuration for stpd / puppet / whatever scripts provision this
                        "host": "science.example.com",
                        "requested_userid": "ak1520",
                        "ssh_pubkey": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3+iRTnUqdbCgiXY3rbVbVXR1r1RbZE/z3Pfxb6M/qz ak1520@example.edu"
                    },
                    {
                        "common_name": "ssh://ak1520@shells.archimedes.gr",
                        
                        // the rest is configuration data for stpd
                        "host": "shells.archimedes.gr",
                        "requested_userid": "ak1520",
                        "ssh_pubkey": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3+iRTnUqdbCgiXY3rbVbVXR1r1RbZE/z3Pfxb6M/qz ak1520@example.edu"
                    }
                ],

                // requested / required availability for this access
                "service_level": [
                    {
                        "src": "141.217.0.0/16",
                        "dst": "192.168.10.0/24",
                        
                        // guarantee 4 9's of uptime between these networks
                        "uptime": 0.9999,
                        
                        // a third party arbitrator can be specified to monitor availability
                        "arbitrator" {
                            "src": "141.217.4.64",
                            "ssh_pubkey": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBQ2t/mwgJm3/uLJ9oyjOquxSivIeuOOTlbo/LwXNSA2 mikeyg@keep.local"
                        },
                        
                        // written in cron time + duration, this is Sundays between midnight and 4AM
                        // these dont count against availability
                        "maintenance_schedule": "* * 0 * * 0 +4h"
                    },
                    {
                        "src": "141.217.0.0/16",
                        "dst": "0.0.0.0/0",
                        // expected throughput between these networks in kbps (1Gbps)
                        "nominal_throughput": 1000000,
                        // minimum throughput between these networks in kbps (100Mbps)
                        "minimum_throughput": 100000,

                        // a third party arbitrator can be specified to monitor throughput
                        "arbitrator" {
                            "src": "141.217.4.64",
                            "exec": "iperf3 -c 141.217.4.64 -t 2 -p 4567",
                            "ssh_pubkey": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBQ2t/mwgJm3/uLJ9oyjOquxSivIeuOOTlbo/LwXNSA2 mikeyg@keep.local"
                        },

                        // written in cron time + duration, this is Sundays between midnight and 4AM
                        // exceptions that occur during this period dont count.
                        "maintenance_schedule": "* * 0 * * 0 +4h"
                    }   
                ],

                // can specify penalties that correspond to violations in the service
                // levels defined above, use 'null' for no enforcement.  these can be plain language,
                // code, or a number which represents a % of a discount of the monthly fee per violation
                "penalty": [
                    null,
                    null
                ],

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
    },
    
}
```

### Access Grant

The grant contains specifics about what the _Resource Provider_ did to facilitate the OAR, it will also
explicitly point out what parts of the OAR it refused or had problems facilitating.  For security purposes
the OAG should encrypt sensitive information it needs for itself with a symmetric key known only to itself.

A new symmetric key should be created for every OAG ID and stored in a local database of keys until the OAG
itself expires.  _OAG_ asserions may be renewed / refreshed as part of the refresh process done in an _ORT_, therefore
expiry times on _OAG_ should be slightly longer than the refresh time of _ORT_ assertions, else the deprovision actions
and/or the removal of session encryption key happens before the user has a chance to refresh their _OAG_.

This puts expiry time frames for OAGs in the "months/years" range, but none the less they should eventually 
expire.

#### For Already Provisioned Services

If the rules outlined in the _OAR_ that provisioned the service allow the _Resource User_ scope, affiliation,
membership status in COmanage, or other attributes on hand to dictate the terms of access, then the 
_Resource Provider_ will take the necessary steps to configure the system for this _Resource User_, and 
deliver the OAG back to the `Central Authority`.  Otherwise, this may kick off an approval process whereby
the _Resource Owner_ is notified of the request.  If the approval process is followed through to completion
then the result should be the generation of an _OAG_ for the _Resource User_.

#### For Yet To Be Provisioned Services

Since it's also (kind of) a negotiation of the terms of the level of service, an `OAG` may include service_level 
counter-offers.  If the _OAG_ assertion's `service_level` and penalty parameters do not match those included in the _OAR_
it is up to the `Central Authority` to make those descrepancies known to the user.  If the user agrees to the 
counter-offer then the _OAG_ may be used to create an _OAA_, at which point the terms outlined in the _OAG_ are
the official terms of the engagement.  If the _Resource Requestor_ does not agree to the new terms, then the 
`Central Authority` must start over, issuing a new _OAR_ on behalf of the _Resource Requestor_.

#### The Header

```
{
    "typ": "OAG",
    "alg": "RS256"
}
```

#### The Payload

```
{
    // the third resource provider in the OAR's audience answered the call!
    "iss": "urn:uuid:F07FB237-7A49-49AA-BDCE-96890E69A637",
    "iat": 1473280957,
    "exp": 1567888957,
    "sub": ["ak1520@wayne.edu", "urn:oid:1.3.5.1.3.1.17128.313.1.2:85B68BF3-2343-42FF-A0C4-C10E1C3CA868"],
    "jti": "51679296-37B9-45BE-BE25-A371CF27E5D2",
    "irt": "E821240C-5494-4B40-8387-5DC3A3B37813",
    
    // time to accept this issued grant by sending a signed _OAA_ containing the unaltered grant to the
    // execution/acceptance endpoint.  after `time > (iat + tta)` the grant becomes unexecutable.
    "tta": 1300,


    // the grant is for the central authority and for the issuing RP, in a way it's
    // granting an OAG to itself.
    "aud": [
        // the central authority
        "urn:uuid:58F1C380-FC8F-4D1E-8C5B-0FC32F81087D",
        // and myself
        "urn:uuid:F07FB237-7A49-49AA-BDCE-96890E69A637"
    ],

    // session keys for the audience members, encrypted with their public encryption keys
    "_sk": [
        null,
        'LAzV51275XctLukGNd5aMo64fGXrMWRJ'
    ],

    // note: the first 24 bytes after decoding are the nonce.
    "_opaque": "koKmyUGgdwCSaLDixLpw4IGMJCXFNK3wMraP8jep7W-ka",

    "granted": {
        // granted blocks have their own session keys for credential encryption
        sk: [
            '0ZHiPJ-c9-v7xTVYmp3n-ONSv7ip3VqZ',
            'xnvg166UrVXJ38UmEzLLNPOT9BW_AOyP'
        ],
        
        "access": [
            {
                "type": "cephfs-mount",
                "kind": "read",
                
                // could be Base64 encoded JSON after decoding + decryption, who knows.  credentials
                // will be handled and utilized by mount.osiris
                "credentials": "YQQyBGepCMfAI-BixF5VEchjVLR8OeJk",
                
                "resource": ['science1:/some/science', 'sci45:/more/science'],
                "iat": 1481772233,
                
                // good for a month, stpd scans for and keeps track of these 'exp' timestamps, it
                // will do housekeeping on a reasonable interval 5-15 minutes.
                "exp": 1484364233
            },
            // notice how we only got read and write, no admin!
            {
                "type": "cephfs-mount",
                "kind": ["read", "write"],
                "credentials": "5wqy45o4JOudQG957JSTARLTcHm4qu-J",
                "resource": "science2:/mad/science",
                "iat": 1481772233,
                
                // good for a month
                "exp": 1484364233
            },
            {
                // we were also granted login access to this account, don't need
                // credentials as our pubkey was installed as part of the request
                "type": "shell-account",
                "kind": "login",
                "resource": "ssh://ak1520@shells.archimedes.gr",
                "iat": 1481772233,
                
                // good for a year (at which point the account will be deprovisioned)
                "exp": 1513308252
            }
        ]
    },
    
    "denied": {
        // denied blocks can have session keys for encryption as well, but this one won't 
        // have any because we have nothing to hide!
        "_sk": [
            null,
            null
        ],
        "access": [
            {
                "type": "cephfs-mount",
                "kind": "admin",
                "resource": "science2:/mad/science",
                "reason": "group membership required, please contact mrwizard@science.com to be added"
            },
            {
                "type": "shell-account",
                "kind": "sudo",
                "resource": "ssh://ak1520@shells.archimedes.gr",
                "reason": "resource provider policy forbids this type of access to all users"
            },
            {
                "type": "shell-account",
                "kind": ["login", "sudo"],
                "resource": "ssh://ak1520@science.example.com",
                "reason": "resource provider does not provide 'shell-account' access to this resource"
            },
        ]
    },
    
    "provisioned": {
        // the opaque encryption key is for the resource provider's eyes only this time.
        "_sk": [
            null,
            'xnvg166UrVXJ38UmEzLLNPOT9BW_AOyP'
        ],
        
        "access": [
            {
                "type": "shell-account",
                "resource": "ssh://ak1520@shells.archimedes.gr",
                // timestamp access was granted
                "iat": 1481772233,
                
                // timestamp access will be removed (t + 1yr)
                "exp": 1513308252,

                // the resource provider agreed to the terms of the SLA and arbitrator access
                // it installed the arbitrator's public key accordingly
                "service_level": [
                    {
                        "src": "141.217.0.0/16",
                        "dst": "192.168.10.0/24",
                        
                        // guarantee 4 9's of uptime between these networks
                        "uptime": 0.9999,
                        
                        // a third party arbitrator can be specified to monitor availability
                        "arbitrator" {
                            "src": "141.217.4.64",
                            "ssh_pubkey": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBQ2t/mwgJm3/uLJ9oyjOquxSivIeuOOTlbo/LwXNSA2 mikeyg@keep.local"
                        },
                        
                        // written in cron time + duration, this is Sundays between midnight and 4AM
                        // these dont count against availability
                        "maintenance_schedule": "* * 0 * * 0 +4h"
                    },
                    {
                        "src": "141.217.0.0/16",
                        "dst": "0.0.0.0/0",
                        // expected throughput between these networks in kbps (1Gbps)
                        "nominal_throughput": 1000000,
                        // minimum throughput between these networks in kbps (100Mbps)
                        "minimum_throughput": 100000,

                        // a third party arbitrator can be specified to monitor throughput
                        "arbitrator" {
                            "src": "141.217.4.64",
                            "exec": "iperf3 -c 141.217.4.64 -t 2 -p 4567",
                            "ssh_pubkey": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBQ2t/mwgJm3/uLJ9oyjOquxSivIeuOOTlbo/LwXNSA2 mikeyg@keep.local"
                        },

                        // written in cron time + duration, this is Sundays between midnight and 4AM
                        // exceptions that occur during this period dont count.
                        "maintenance_schedule": "* * 0 * * 0 +4h"
                    }   
                ],

                // no penalties incurred by the service provider for mistakes, as agreed.
                "penalty": [
                    null,
                    null
                ],
                
                // most likely a deprovisioning script / configuration / instructions / love letter
                "_opaque": "ZVgxNSm_OjlO9xiMgVuToohs-kJQ-iWHzcFugbiO-pSLw70NINKrwU3kndJ-GwbUt5amQI3Czj5h11f2GLGYnHze9LDx20dE6ppQxoDT-tRmzMfivl5H0RP74Cep-RFS_5vTohn-pkHxfpk1H_y6hnEFMkJ1nfznY5z2dJKuq-R9ZkHkAeqvdDJjLthDyf9cumLkfjc2msVoyyhB0Yl_9Za3ICMJHmqXtUqd7Giie3YIeA44KIz2mOy74vuyJxhnK1liG-1Xu_D8ZDS0jJmJ_NUBfbdyCGIvIX9Jifroc64hqm8Lsb5Yy2IoAKwX3UI-mMvCSXoqdsdzt8cuIDdi9Wxw4upcFeBOXweZoQLrGCyswOqswrlbs_Qk6gJIpyDmD07NrTrfqlNsD1XyFvaptgAUR8Lj03PhomhCty0-sttqh7abbV-hNbwsr4hXQ-dImpuBdwcCS4TR-b9lbqHsBk4mRHQU6lmMbRYBZMOy_Ntb1LgC6nwbtbfMb0qxabY9"
            }
        ]
    }
}
```

#### Grant Limbo

Before the grant actaully causes any changes to be made on the Resource Provider it must be accepted
and turned into an OAA by the user (via the `Central Authority`), the amount of time a grant will stay
in limbo will most likely vary.  15-30 minutes seems reasonable.  After this time elapses, the grant 
will be purged from memory and an OAA creation action referencing it will fail.

### Access Assertion

Oakd / the COmanage interface will digest the myriad information stored in the returned grant, including
what was and wasn't provisioned.  What access was and wasn't bestowed, and how the situation stands.  The 
`Central Authority` will allow the user to review this data in a simple form and either accept the _OAG_ and
turn it into an _OAA_ or refuse it and start over.

If only some of the users needs were met by the _OAG_, but the terms are acceptible, it may be in their best
interest to accept the _OAG_ and then issue another _OAR_ to try and obtain the resources they didn't get in
their first _OAG_.  It's important to note that accepting an _OAG_ is akin to accepting a bargain, this becomes
an official agreement.

#### The Header

```
{
    "typ": "OAA",
    "alg": "RS256"
}
```

#### The Payload
```
{
    "iss": "urn:uuid:58F1C380-FC8F-4D1E-8C5B-0FC32F81087D",
    "jti": "DA342910-C676-4A4E-9095-333652FCD8EC",
    "irt": "51679296-37B9-45BE-BE25-A371CF27E5D2",
    "iat": 1473280947,
    "exp": 1473280977,
    "sub": [
        // a named individual subject
        "ak1520@wayne.edu",
    
        // an osirisEntityUniqueID matching a comanage group within a CO
        "urn:oid:1.3.5.1.3.1.17128.313.1.2:85B68BF3-2343-42FF-A0C4-C10E1C3CA868"
    ],
    
    // OAAs go to the `Central Authority` and the issuer of the OAG
    "aud": [
        "urn:uuid:58F1C380-FC8F-4D1E-8C5B-0FC32F81087D", 
        "urn:uuid:F07FB237-7A49-49AA-BDCE-96890E69A637"
    ],

    "grants": ["UisJLJFOXUFyluaBHhsUQ1n.kCHwsBKp7kXNtMeBO4MlklyFxbvDwiyqGZ2vFCEGqhJi4p7chenG-R2y3Fi041KsZfjPMC8qv0V2nygU5QBHWx_QnvBzv5df-fawNUQxBI1yx6ZMDWdpiK3S6DYuRi2OWvpy0vS3LIAbFy-sT-KSQhEvFt7ElBCWttrPu6Cxfzuz2JDcCwgNQuVV9mYGRtv1JL8AtxC1EV-zMAkmV1fVWTeonQ81KO4UuNpxzBqwNfRCezUDiIt6gost5VI_hrKM-bihdCjCP5CxkG8X49-uWiydy87bwZUFY8VxivKkbHaXrYSVHM4pIBHWG3Lzjsm5-RerdzHDrb8dzBeB1t-paBfNxoomg0uCeJrxrIwsOBJVX4lg3FOxyViH_kd4BbUmDL65t1Z0fivoVNdGO_C-4zFrO_P4ZO0q3gapMYBbpYwGHvhecXpbp83f3oRn1NTG8d1ki0RSkZmiPgdRA-9XIx3DBD-MLLvVKmH7ixpfmo7Znzdjhopmlsczr2Tf9fTS0icaMZ3uNLvAkwZvhyFLtTrnZWpCgHwocY1OTt9Fc8nHLdEeYVv-9wq_zW7PT0Kl85L2349KFJbN62sopUFKiYPQnuHAEzx9h1NLczsAWnOJIRJhfm626uPeeJlx-N57X5BJjBLnxdVI4JkEAzjJqpyslEXaeeqpGYBl3jeOAMRxkzTaCMtEGs_TRqXvB0LkXxDZGFfVJDm_bkKcmN4d1RzGxed8WZP9vyA41wNyKbi2N1KzAYjfhioKPhkuplDzo45iJkiECYlV1gTcONas6VRRlcmZLgEcBZWRo5d3PY0ZY7P1KOeeJ13v8SYbUnDpKD3IDBUEJf_NfmseDoEZX9hSOvIpldx4I4v5DaKVIuZLVckqnL-5V-3lRQo3wKKCFgiQ_8jBucO4Fjnh0GDHuVH9vaiQLvqUzo5NheVGa_4PN2GMzX8dinoYGiGGNDcMJtp_wU92J3W96hKPYGEOD5P0LYUtT1eEJhV1yh1tyD7NNlGxGg-5t0rynCKxekzP7xRbfEs5vdNYImE3mZqj2LktnLzXwkfmM68W-AXQHL90lS-SzGbSAQlEQSyPo5yHuoK8fweggAMlEJXWkNWERUaSqKzddZcBLx4DB8mO-2TdMyTGm_95RX8I3Lk_xTzR_ElrANzkRSbz8HpfQOpRtPWPtO22YHDQixqYob2oOUArk6tarImGXArBr3Ga3t0Hyt9Bq9b4K07zQc9bU3TVZi9OrPgpeQ03LKMHbNt4bHwj4BwNH6itx6cktAh8vQKV8opQ9mdzbj8F8t76NpnCbb7Q-oftTlmGICB03FUlmJDG2lnT-n_dmcwkKry_u_qxGB0723TelW_cA4Iv6OGMOrSHH4p6UcGJ8gwu_XoeQmq_yBWPQZZZ0mYO7dMP75D4l5RR_Bd-wCsjf-Kgclg172poqaakGkj6cGxchZITQC5YhUgN2g94gl5TLseM-TKwLFsiqrP5ynRAT05WrcBfV-LL7eaP6JvANL4njCemsTBfZlALEwlV8J_S5jRL6BfW79ZMHn-aVkoDAbYaOwtPe-H7QuaDRovAUNtEoa7-yy2T_uFn_UV-wQFkIPOcXPs0lGWOR8oxpYjx5DNr3xp1nxIzWrRjSJTeIu4QqeY4twli6UChn2sg6JxgVfWEU1KI1ka5iVBQKL8hOFoqOGX5zZzWboPB9cPMxMGOHJpuTtliwbhv-iBex2ahk0Ay9YY5xtz7zWv0KQtSuIlNRKXDB6FBIHXMQdkHWp67HvwUlMJoiR2GE2zF-5B0Oq0XYFH0ryo79Z9X64K73pEsqQm6A_0-YqHnXaBnFOXcU52TnZQkNEKR53aH-JJ4s05PMd0x6e0RCC6SxgqZRerSqjJlWum2XWn5-LXvShTHsEif5F5laN3l29UgiyeAoL_WNe9eL7xvIrEcfl5MA1dnoHb9oECpP7U_Evr36wlqO7K1Ixgv3Y48VyiAQgHHsouOv5fr6PHOdWF1ck-O7x6Sny1pVEofuroBvm_O1ARjHhXqQhNAT5hpAF7jp4_PvfIlbJkDqj-WBQcoPHz4UBWB4rVSzVPmWWSajvksfcVw2Jl13biwNgSVQAbMuKsDOvIVHCwJeEbc2elF0uH_8MQqltFxNZE27pDVXhBf6_DpAKh_cEo8nVuEdnTrA2NIcKP8Jb4WRhyBDpxR4-HybJUVZ9qdUNNLyOQ-L9xAT0D8c3xwBOJdTcG3U6QGjel61xIciJi_Dy2czb9G6K_BMObah2e883RpV78MTIzvHOXZvG0X4mm2lxvHPczcDv6x5amYTzlBEsY97l3hO0yYW1k-_oiUQJxZlAktCVWtMXF0xuGC9ttWrrE1gs7nFO2h87VmRdRGnj63UEsD8a4yzAXm6eM5igPC8MFYnyqhRrAE1N-WgjCb9n_jXRYtBjeD5CJxR5DrIWNcrKmrxub7HKmjkw0nP2_gOdt2Zja3vkdRaYkqFs195iPsPQwfNSMESgzAVtLr1I5IFGNzeH8h62oa6K_bdX5WR-6k9kNceCXo3lxsI6VsNRZlacVGZVfpeC3p7igDzV_bnfEyaJU2dDP1yzXug0P_FZdHtuiCTtS241Jth1H-RYw8u6e2XjxLVTTs06BDQmrTrqeqEp7o01QaOvqlWyfyaQRP1grrtO3MpTt8O1r4WAAzfEo9SCjJvfTMtjjtifZnUyuuVo8iWSbiIuH3TetBS8uDIquYxSdz88TltN51iaOhcaA-4Z4ZwF6y59vJPvJmiCt9OO55ucNkHWkiYeJ_nvUq4zjEEPZNlUVu9nfudr0OAdRxD43e6fZPTw03OrYOMZSKY671h6vBfj5fy-hvbSafl8pDcDEI40Lr-HExxrgOmOnpop4RKbpKSSLwgXvj8S43zpLLDk6q41HtrVUyHG1IEOYMc6HM3IimFqlAG4zUoZLU4_BcNEaMlFoU3Z0VHF7LZpSjntVfuZWM2QPIaGN5aTnpQfanMyuGn0gMVIPJcUlvOshq9ZFHvpd7XUPCtvQ1nAhiQ2HeMA-zFokpVUkJr8S7oum8HcQVBZ2GQFcuFx1l1TedSL-p1RBcLkU94gcoE8makJkl8Zqo-TC32wJwbRTa3_1iNl0CJgpnD0PvnrR9fBY7jwEn4KgK6UO0fyzGWXK86xZ7Xe9w5Hmm94cdswv_7ezpbxpNWSEkS564lbbd4FwOqSXxrUEWJ3DXIvFt_S4GkMdF-P7LjyuTglJyktUJYX0IkFfBpnRRbwbIlXtuEXdrvNdPr9v-BfKILKaorbjKIWhp0SXCaTMrExnrime7yHrJL4SrnJModEjawXFRldAcgbAlf8R_i5Iz_WkzLn2HlKEFHK1u2q4LijJc1wn_OSUDB3xrqz3HT5rW3X_Oopp7fJdQ3rkJ4UY3Nff9ZHuT_SCNBWMGD_RpgrlUNGIqMp7mDDd-zSOH4t2BpPip2v0dviIId672XhbWcPNqF2R_9BsiPbT1gEkIz3j2GFVrqyVK0mm4RwhNT0RGnrpzuC87wPa2CfN0UnFCwee8SmRYlo5B-e6qCyajCArLcOknFOGyHL1xOeQp3Nr-NfgDWo2DuCIDfEBzZ4FcT1NUhhhAQd7Ux7AepD7JNGlPwWzXvU5jTltsPCgTDvavhFR997kThQBh2ouJ6YLkeCEriOYCHVgO_oUfPS79qKy83EaRR86ollgeV-hHtPlPz8aOfnf76wL_tkEnwQyKYAbi3zgK-gCq9S21_b9ispH2lNfrjVB0SO2Y6UQU6Cm7_RT7tc7ggNQWnHGkhnMtk42bFJAHCMmKYnTawbmCBA2tJKKnQAblbo-FnsorAG2W9g2vxuinRyQH7tpnRAM3KkmpABTHVFlu33hYMi9LYVgwqh4UOUn9MsiEXraOktDKSBDe6dur6_7QDFnf294tR18XLWyXx4eJnQd-FSgTj5trvtYmsweQoqdQRPF4DD5NAQLvyMve-jDwP0RA3gALjw2h-bVWKmKsHdRZRQXu5F1Urf8HB-xVCU9L71X4P7l3da4-dRE4JZGkUfqr-iKkFmyfHuF2Xo50yq9YUDRrTXUwpKHoizs9P_tYUoouEDns5_VJJb6K_lzWFfvQ-XPtm0XQop0CCnOVgH3Yc4FAJ03m8usz89kLOzhwV_Bq9wg0LKhAyj99wDd9tXiI4AKHysWF3HKNfcXmDwcHbMPLOJWjx4mWpycFyyxR6wODY4EzmIlc_GMbIBV1V9Ma7_KOkkCZHC7L8CcS8qUs0yyYWDV0LVvKcA4hy63MGyGCg8na7d3W2K9tpLVZZqSstTsUMtpj1Dzbx3JwE6HcGeOAUCs1ROoJEyLpfkz33vqHXNsV3ZcaWmWB2-R-QGXnYBXunrwP0omA6ys3OFqui-xooqfbh7o_MKJLbuGFCC0KuIrMZwnRV8y853Ipy87vjsEGC3JilfAZwiDSmobFioH2pk01bAmh60WRuXybXKdkiRBV7U4EgyZY8TSFTsyNRE2_FQ1sOZy43MTdtLyODHZS2ObJeLNtBdXEvDhwPyu5dMRJGhcjcCenUDlSKcr00kawHKlalIg5Kq_Fo8UFEM19_LRU2KSjTH3wxYzFZmVA_zAg1rFGu6g6elruPhe6uPcIK9WQ2zsWDOu_9ySKm64eMwSKRi8dem15LJBRlYqVi7d0hM1CeKUD_pNj31_TvBtQZGohyRiXQQADhFcXYnSSqiUCqdG-dWkXHkKBeyo3O4KFxLLNHOs4zA9swsj74rROrfC9Ve4OKt6X0LMVKExJX4vo-VZ3VbjQKOWx-ftEalAxY2XBQ9_RfFx96EystzYHFjKSn9S5OlLa35nR3gtI6_KcK6KYkAlzeIZzitSHbP7625OxbWN_esThff7i6uzcPiQo1WQP89dh48f2yqcm2QxHTUsPXz7CmWH7zHTWSXnNCIevZggPcvRFxa-2VLVMDuVY0R372fTdNj1JnTLUH98IEdVsTsuD5CIBt0j-7Oz7nXmEVk9frxfjRNaQCsOlLp433aRj3ErvV_Zvo3WTqn2Wb5_.nK1ZTdZqlUJ2wQIBRTcMrF-YVtb2m1XWLAzpZQ165YffSd7mAQNIrjxh27CmNJoBeDnbkQ2zxWyvbUoVlIxwpPVdWQNN-lymSkRUaOEpzoUzjBQ3LEj1Sj1Xyeqfa2fjFT9zUYR1q4uGrHRYUZI8DMAk9WPv7_VW3P2nbOrwk-eG6lGBecT1PNnhWexJsfT4zxhRvQLDerzpj_pBGNv0F8ZnMqRY8crcBJ3AuSr1pkGtom7740-ITGdxn0uP88px7biw8fxKs1skKhZb2ufCPi8D52t902ND-hffue_vZuOtYSm9A9VxY0Q5C5q1O_GEDR2tLC0jgsdHdH95_8h_AhsMmsRkSGwzMbuGweUxaKDJIlt4MVtE86ovraHz2kBSgKYOlL65Tvg7CbB9SxHmrgAz2SNi6OSt0Ea5QAoMc8yebAap8kwl3ZE2t1wi3giJxs8XQWBRWGfBtxWovDTWxnVcvbU4tm8SBjiPw7weaEIpoBdyfMWXqMt6e4IyvpSyakiuBpQczkP8yUNHI2P4qMYfuMU5BwG1-1SSekc2CorUOthmECqgF_lS8xNGGEdsmVzTOx3z-v9fWACoT2S0jeWIefN8qlo2vBxpiWIvVNG7QINC5SwUd2Qnc1MwJXcYd-z5CwlXN-jnQbM3DKyU8u9sc7WctSpnGVylBz_6mfVuhyXm3geee0ejHxQHKKZPRZgoQMvOngg6Q2kN1tjaykK1QvvKAd99kTqLPt2J-BtC69inXoi1FeFPuyIeSen4EZqOSVRA-MOAz4bSb5wDtqREBRP22WAy6wcQKvf9vj3N6T0DeWd2uvxTDr53iAP5iiOvGEO-bEzQH1ovCj_p8bYPKUyy3ehiuDxBUFBrXTt37XtK56NghNH3oyiZFjfPI_xejsg-y33p33pZOxuK8HbPh2pvAUFwd0Fb_qR8rSpSrctT9sgW-u5WyL7_562xEx-FXIBifktJFgUB6uUolwuJ1kVaemP5fdDZnn0HQ-WeHtOI42JU4_ZGD99c-3SB56eVVRwi8o_rQ74b1qWeUtd6pYHaitqHC_UOAqGqDT1Si_NbiRMIOHKTXER5LLLOYZXu3sx9MbktlsAWshh4p9JQp9it52XlXO7Q44Eah5F0vH_u7mAyeHA7Cm0E1mpqdCGDvUTrFrTBuMRdapU2KVvh-KoNGAmUQWX4tMpzjn4OulqqKrWOGVDJzuFIWVOSIWq61PixGhz2Gc7lKvANgx1TtnyctRogkwOK2DYQFNxO0_KTLbq32miHE9pcJQEBKtVnR5qk7zSmXBpel-pD066u37Xj7nyV6cxykjosn9Ys6RRtPSwkKE3lkZMsluke8IEugq5QgqIf_4VCqE-iPgciko9YvyIw7DBqP3CPa5rghhxpA-RYmuVpvMTB7tbtPXBRl0E3vYya2S5YroU6rUM9acqf90BGv0Fq_36WDIulUon07aSHlbYJTqmfGzqymWIZmXNt2jS-VSUOpNMzheTzC2ygg4gqxZD7SKV9CSONy8hJeFMMs87QpvHG5mJ70SwShaJbnk3DiNh8FBgFdz6MwdIS2CQ33A0oUAnE6fgIwXq4Brtaf46E2ZvmlrkOPnE2quuY-VtTPGQ3OENxZM6ZyrOKeAruUqbl5SyTSTlO_JfUIBNQWwMb0_5-nEbJCLmKGxSeQTJj6ZUgHhi-tJQ4iDp2RPl56ZOHbPBnGBqlz0N4kJ3LLCkFqx9XGWiNrwEeTaaF1A0n_FSZc5kjphetrOXxeWSHlJFz-krcUSw6amer5vCa6BP8ZRurTGhh9HSJWMbkOuOBaexPkNr3fbgalSS9XovGIW44X2lPDFpYS_T8Wv_EgpIHbVxO2GUV0Szpl2kiBWuenpCMr-ih1wXWxiOJQDFgXhWEAHICzB7irlP3yJIBiDQl31AEYxKbSMfBgmQgkNwaoe8Xfm-7Mrj32fmfqpiGKP_WSMi79Z_ZOiwnrPT4h9okdX9y13ylRtSvOfL1-8X4bJgswwHUSHnnWmrO1XRUW0UX0ZRkuZrbo0F9Q1tcjUpJZTY2jkPR7-bVcUVOJIFFTBvUljYc3uFdE1fzdKo9UVByJ7VnCeSqZRPxfqW2GySTSej0SKyqSfctN-4t-ABgcx8YB-oY2qRYTaKGd0O-WwChIkizOkfe9TC6n_Y5z1mSCKMOWVnijy5gGjnfvuVYbRLiXtjWcAIeTx7gr3Ro3fVgn98R5kT6H-hV6cJitD3ch79cSyeDkrq80pzzTPavGcDvvmf1ggdoUnEDaur6gnOZem-VyN3LsN5LMWg7AEde8Tx4AAbwyYfMITxWJ0x5IzrLZ-xFuPEMJkxTQ6wy5T0olbSdBhFJULrvVGAc4W0uYk8CzsUAOQxn6HJ2pHecAN63vnAn9jS2MnN-knqtpMbwyR2J8Rov-HaWlxL5Xuf6oCiF55yzGCoeWuFxPpFlREubBImDbUtxse4CBDeYkzKk3VGLVt8RZdZzNWgKDNlO_wagrbSIcS-30Tv1nY0PKV1gT2AF5gOMt3zDU3TXBDNbtca86Ew64Vmr_vtRHvMp6Gf5OFEMR2184hA6ss2GrK5SRQhyitSPkSjuGLABHEelMP4-4HiHhQ16aILZGRAinKwdu2jAoJ83n6re2z8bnKrMrj1jiZGZFU5ZvcS1yzyNBaaBBz2QY8Ux4fUgzL2CQk9tREqwjjXwsjNHPCZvFkWSY1At-aN_QV8VEJWIqhOb2nSsntH1jvE1R2SPrbOoIYMmT6iBBlBvaiqB9z0RFKMPMM3ShVGcDVf3YvAMb7KJSU0iMsK_gmKZQRinS99WWxZ5z3JxSjDgvJ_SxdxX5j8XogxPpmcmb0Wh7KmNMAGoXmsPKf9RwFcuUMk_mIqxnZc7murXiM4eVDu_ij6brlXdJWf5bS047VuAruNUW1kV6m-6mHQ0xTZMTiUWcr893tYL4GyMZIICl8t5lV326ROZ_jB-8mwIhz5eh7YPjAEWJHmu6vosf9HdqZb8hO-91CTRkud46efCzhcAq-afT5DJ4M4-WdCBW6IuBdzGqJh5ZR7KZPnStcy0RMMUaLgdKRDw1B9SqYzd8bI1suqXRy2Ns7mwwX8fbq1GkK-J6vHuy75M2svjXXDV2wzspzF6MyWDq75Fr93TZEMPv-2YNa1FvE_KeSZzy9P50vrd_ZP2bbFiTUEvlRwjWP2mQSiCNkAPJv0zKgCIPmhx50cKvox4fpx2t1m3MjtM4TnbO1n9jMad0vLEEbWeap-HK6iYakpuOFHtcyBVo3NlbZUtD_Loq94WE6sXh9UZQBnhthxv6PNfwCVF2cRQZTUkvSfnc15b4YqH5S683Ywtn2FkIz9-99YmycavxSqdAUylQvoO-2tJfLWqGpl0W8D9NawJLNtHZzx-iRmFL4RlWAy2T-MKulvep39bTj5osJTcRObPOEEO_bys7Lh2DHtyfZaxtz0Sp_X0kw1Cp4ypMKjkwN7fkFws2WJFG0et1d_ACphk7ZyQGeJFuKu0_unwNrBQN-qMAqhIovQZPvzmxd0pS70odD416N2pdVQjhUEOcp17qbvGZedhcZJqR09T1NjeX7CqNsUwi7Fz5iCGMGSA-6k3lrwY_MIpKActI6XZWuT-P6_oO8rM3YXVG0TEtF0ZhzWJqE61TFOJbhiB0_077C8EkMvW3EP5FO-KgCjPAksOJpiwpMdrYRK4vtasQZ6nNxvfvhHO3mGeaVLMsU12fvWTfAMRn8JclRdJkIlB2XqTwpZksg7sNBFc0ZvDaRtqtH1RCwWkw-r8rtOUpqzLCvSF7MCMSj6uK1p4XG83n_zKyHcDjuEsn4ntjz7abOyOiI5vR9u3kxM7tnT3kLeKc04hved0LFr2BakZciTIUzfl7UfZHJr-W5_BujQ2armoGVs5oMWHAXq7aQDBW3d46KJ4_DrchoEvu-0WBV7G2c2QUwMRyy722ilKdjaIK7xkDcTZIc1AnkBKo_5L-z3MKhDfJ-lCTRepsApjcquUbv2nanT6dzd99Sz2V65kqUtcQMPNBI1pJjZM9W7gCeC-Y6US36_sHPSS0-A29IQV5x-5_5TueYdJiPok7RTh8WSMKHhmMbwrhcFPopGhbt09yebLz7KFv0hgnwvm2Xb3vgtl3EBfnS-TlphT56stFQQe8fX18OZBPtfU-XJCyx_aIkhcIyrprW9DleJpW88e0K4H3hjlfqNZevAA99djo2AITnKeopqiX_3YIZC9mMez7xkEy7gk1ousqR61eIQ6KhhT40NNC_KgHAfOrQ5jLOo5CjOgUDxOGEyITsdlWUW63EJs42Y69ttZ3QQl9QsqLUxjd2AYIOfsU09BOG4wc_NijTKRYuzCGlBOcuBLAlg85lT1Lxfzt_ONykE8Vr4ntxILJuWPgvmdnJCXb4nKR9SgXYhZpLw-9oXY8T1Y4SpXxp3Nkf51QWRlRyCFvETRwuuJX5vIVj7Kcc2o7LGFEye9Mpnjyc6hcZCW66N2HxrPN8bffAi7WneuuIuRG1GApo8GhVZT4xpI0PJws7UZNBEeDjIYApxJ-eS1WKt9t7I4OWgBC98SDgLD7iaV1CtBaxnIDufPKQS_fCPiIJ63SsTgeIetdNRt4eGiU4cJys20bBdO51VBphOubIkE_ZYiXOnzrGBs9GdBXTwyDUCr542C7thhV6VvwTlsJgwiAHY_cI6Att8XKkLS6pVfMTwU9pMGHC3CdM5_itnh0F5WibBrbIwi_IF15aNw7sO9YEDvKrKnYF0vXkjfPAA1hCCoq1E18OTudBgtASVz4-IC8zIsDCBWDQzI5FKKkfWDVBY5-Ty7YIeGeHuxchw4IEkWfg3rKdxAexSGTHDx-ii_eI2A7Wve_HE7yDBfHLkJIIYPjasqTSbNRxW4pQlLQvz-Vm-DsP9cuL5oP-W6oSHvWbyRSiUz45FQqkux-bZx47cAOPpFOdmX_wNkiFoTkQeeOv2Qyt7kEnkP-04BL6t-QD2zRoX7Je_Ws8SuKcEp3iQU6OXxxN1CZlJiPmmKxn"]
}
```

### OSiRIS Access Token

#### The Header

```
{
    "typ": "OAT",
    "alg": "RS256"
}
```

#### The Payload

```
{
    "iss": "urn:uuid:58F1C380-FC8F-4D1E-8C5B-0FC32F81087D",
    "jti": "8B93710C-2CA1-458E-A2B5-F7DE378815F1",
    "iat": 1473280947,
    "exp": 1473280977,
    "sub": [
        // a named individual subject
        "ak1520@wayne.edu",
    
        // an osirisEntityUniqueID matching a comanage group within a CO
        "urn:oid:1.3.5.1.3.1.17128.313.1.2:85B68BF3-2343-42FF-A0C4-C10E1C3CA868"
    ],
    
    // OATs go to the `Central Authority`, and the agent running on the user's client
    "aud": [
        "urn:uuid:58F1C380-FC8F-4D1E-8C5B-0FC32F81087D",
        "urn:uuid:0008A93F-63C1-4E65-B99D-570913AF13BD"
    ],

    "_sk": [
        'i3lDEXCanXolVL5VHaLd5F2',
        'qk1_GzCkyd8-4X2V1gVVdBt'
    ],

    "assertions": ["UisJLJFOXUFyluaBHhsUQ1n.kCHwsBKp7kXNtMeBO4MlklyFxbvDwiyqGZ2vFCEGqhJi4p7chenG-R2y3Fi041KsZfjPMC8qv0V2nygU5QBHWx_QnvBzv5df-fawNUQxBI1yx6ZMDWdpiK3S6DYuRi2OWvpy0vS3LIAbFy-sT-KSQhEvFt7ElBCWttrPu6Cxfzuz2JDcCwgNQuVV9mYGRtv1JL8AtxC1EV-zMAkmV1fVWTeonQ81KO4UuNpxzBqwNfRCezUDiIt6gost5VI_hrKM-bihdCjCP5CxkG8X49-uWiydy87bwZUFY8VxivKkbHaXrYSVHM4pIBHWG3Lzjsm5-RerdzHDrb8dzBeB1t-paBfNxoomg0uCeJrxrIwsOBJVX4lg3FOxyViH_kd4BbUmDL65t1Z0fivoVNdGO_C-4zFrO_P4ZO0q3gapMYBbpYwGHvhecXpbp83f3oRn1NTG8d1ki0RSkZmiPgdRA-9XIx3DBD-MLLvVKmH7ixpfmo7Znzdjhopmlsczr2Tf9fTS0icaMZ3uNLvAkwZvhyFLtTrnZWpCgHwocY1OTt9Fc8nHLdEeYVv-9wq_zW7PT0Kl85L2349KFJbN62sopUFKiYPQnuHAEzx9h1NLczsAWnOJIRJhfm626uPeeJlx-N57X5BJjBLnxdVI4JkEAzjJqpyslEXaeeqpGYBl3jeOAMRxkzTaCMtEGs_TRqXvB0LkXxDZGFfVJDm_bkKcmN4d1RzGxed8WZP9vyA41wNyKbi2N1KzAYjfhioKPhkuplDzo45iJkiECYlV1gTcONas6VRRlcmZLgEcBZWRo5d3PY0ZY7P1KOeeJ13v8SYbUnDpKD3IDBUEJf_NfmseDoEZX9hSOvIpldx4I4v5DaKVIuZLVckqnL-5V-3lRQo3wKKCFgiQ_8jBucO4Fjnh0GDHuVH9vaiQLvqUzo5NheVGa_4PN2GMzX8dinoYGiGGNDcMJtp_wU92J3W96hKPYGEOD5P0LYUtT1eEJhV1yh1tyD7NNlGxGg-5t0rynCKxekzP7xRbfEs5vdNYImE3mZqj2LktnLzXwkfmM68W-AXQHL90lS-SzGbSAQlEQSyPo5yHuoK8fweggAMlEJXWkNWERUaSqKzddZcBLx4DB8mO-2TdMyTGm_95RX8I3Lk_xTzR_ElrANzkRSbz8HpfQOpRtPWPtO22YHDQixqYob2oOUArk6tarImGXArBr3Ga3t0Hyt9Bq9b4K07zQc9bU3TVZi9OrPgpeQ03LKMHbNt4bHwj4BwNH6itx6cktAh8vQKV8opQ9mdzbj8F8t76NpnCbb7Q-oftTlmGICB03FUlmJDG2lnT-n_dmcwkKry_u_qxGB0723TelW_cA4Iv6OGMOrSHH4p6UcGJ8gwu_XoeQmq_yBWPQZZZ0mYO7dMP75D4l5RR_Bd-wCsjf-Kgclg172poqaakGkj6cGxchZITQC5YhUgN2g94gl5TLseM-TKwLFsiqrP5ynRAT05WrcBfV-LL7eaP6JvANL4njCemsTBfZlALEwlV8J_S5jRL6BfW79ZMHn-aVkoDAbYaOwtPe-H7QuaDRovAUNtEoa7-yy2T_uFn_UV-wQFkIPOcXPs0lGWOR8oxpYjx5DNr3xp1nxIzWrRjSJTeIu4QqeY4twli6UChn2sg6JxgVfWEU1KI1ka5iVBQKL8hOFoqOGX5zZzWboPB9cPMxMGOHJpuTtliwbhv-iBex2ahk0Ay9YY5xtz7zWv0KQtSuIlNRKXDB6FBIHXMQdkHWp67HvwUlMJoiR2GE2zF-5B0Oq0XYFH0ryo79Z9X64K73pEsqQm6A_0-YqHnXaBnFOXcU52TnZQkNEKR53aH-JJ4s05PMd0x6e0RCC6SxgqZRerSqjJlWum2XWn5-LXvShTHsEif5F5laN3l29UgiyeAoL_WNe9eL7xvIrEcfl5MA1dnoHb9oECpP7U_Evr36wlqO7K1Ixgv3Y48VyiAQgHHsouOv5fr6PHOdWF1ck-O7x6Sny1pVEofuroBvm_O1ARjHhXqQhNAT5hpAF7jp4_PvfIlbJkDqj-WBQcoPHz4UBWB4rVSzVPmWWSajvksfcVw2Jl13biwNgSVQAbMuKsDOvIVHCwJeEbc2elF0uH_8MQqltFxNZE27pDVXhBf6_DpAKh_cEo8nVuEdnTrA2NIcKP8Jb4WRhyBDpxR4-HybJUVZ9qdUNNLyOQ-L9xAT0D8c3xwBOJdTcG3U6QGjel61xIciJi_Dy2czb9G6K_BMObah2e883RpV78MTIzvHOXZvG0X4mm2lxvHPczcDv6x5amYTzlBEsY97l3hO0yYW1k-_oiUQJxZlAktCVWtMXF0xuGC9ttWrrE1gs7nFO2h87VmRdRGnj63UEsD8a4yzAXm6eM5igPC8MFYnyqhRrAE1N-WgjCb9n_jXRYtBjeD5CJxR5DrIWNcrKmrxub7HKmjkw0nP2_gOdt2Zja3vkdRaYkqFs195iPsPQwfNSMESgzAVtLr1I5IFGNzeH8h62oa6K_bdX5WR-6k9kNceCXo3lxsI6VsNRZlacVGZVfpeC3p7igDzV_bnfEyaJU2dDP1yzXug0P_FZdHtuiCTtS241Jth1H-RYw8u6e2XjxLVTTs06BDQmrTrqeqEp7o01QaOvqlWyfyaQRP1grrtO3MpTt8O1r4WAAzfEo9SCjJvfTMtjjtifZnUyuuVo8iWSbiIuH3TetBS8uDIquYxSdz88TltN51iaOhcaA-4Z4ZwF6y59vJPvJmiCt9OO55ucNkHWkiYeJ_nvUq4zjEEPZNlUVu9nfudr0OAdRxD43e6fZPTw03OrYOMZSKY671h6vBfj5fy-hvbSafl8pDcDEI40Lr-HExxrgOmOnpop4RKbpKSSLwgXvj8S43zpLLDk6q41HtrVUyHG1IEOYMc6HM3IimFqlAG4zUoZLU4_BcNEaMlFoU3Z0VHF7LZpSjntVfuZWM2QPIaGN5aTnpQfanMyuGn0gMVIPJcUlvOshq9ZFHvpd7XUPCtvQ1nAhiQ2HeMA-zFokpVUkJr8S7oum8HcQVBZ2GQFcuFx1l1TedSL-p1RBcLkU94gcoE8makJkl8Zqo-TC32wJwbRTa3_1iNl0CJgpnD0PvnrR9fBY7jwEn4KgK6UO0fyzGWXK86xZ7Xe9w5Hmm94cdswv_7ezpbxpNWSEkS564lbbd4FwOqSXxrUEWJ3DXIvFt_S4GkMdF-P7LjyuTglJyktUJYX0IkFfBpnRRbwbIlXtuEXdrvNdPr9v-BfKILKaorbjKIWhp0SXCaTMrExnrime7yHrJL4SrnJModEjawXFRldAcgbAlf8R_i5Iz_WkzLn2HlKEFHK1u2q4LijJc1wn_OSUDB3xrqz3HT5rW3X_Oopp7fJdQ3rkJ4UY3Nff9ZHuT_SCNBWMGD_RpgrlUNGIqMp7mDDd-zSOH4t2BpPip2v0dviIId672XhbWcPNqF2R_9BsiPbT1gEkIz3j2GFVrqyVK0mm4RwhNT0RGnrpzuC87wPa2CfN0UnFCwee8SmRYlo5B-e6qCyajCArLcOknFOGyHL1xOeQp3Nr-NfgDWo2DuCIDfEBzZ4FcT1NUhhhAQd7Ux7AepD7JNGlPwWzXvU5jTltsPCgTDvavhFR997kThQBh2ouJ6YLkeCEriOYCHVgO_oUfPS79qKy83EaRR86ollgeV-hHtPlPz8aOfnf76wL_tkEnwQyKYAbi3zgK-gCq9S21_b9ispH2lNfrjVB0SO2Y6UQU6Cm7_RT7tc7ggNQWnHGkhnMtk42bFJAHCMmKYnTawbmCBA2tJKKnQAblbo-FnsorAG2W9g2vxuinRyQH7tpnRAM3KkmpABTHVFlu33hYMi9LYVgwqh4UOUn9MsiEXraOktDKSBDe6dur6_7QDFnf294tR18XLWyXx4eJnQd-FSgTj5trvtYmsweQoqdQRPF4DD5NAQLvyMve-jDwP0RA3gALjw2h-bVWKmKsHdRZRQXu5F1Urf8HB-xVCU9L71X4P7l3da4-dRE4JZGkUfqr-iKkFmyfHuF2Xo50yq9YUDRrTXUwpKHoizs9P_tYUoouEDns5_VJJb6K_lzWFfvQ-XPtm0XQop0CCnOVgH3Yc4FAJ03m8usz89kLOzhwV_Bq9wg0LKhAyj99wDd9tXiI4AKHysWF3HKNfcXmDwcHbMPLOJWjx4mWpycFyyxR6wODY4EzmIlc_GMbIBV1V9Ma7_KOkkCZHC7L8CcS8qUs0yyYWDV0LVvKcA4hy63MGyGCg8na7d3W2K9tpLVZZqSstTsUMtpj1Dzbx3JwE6HcGeOAUCs1ROoJEyLpfkz33vqHXNsV3ZcaWmWB2-R-QGXnYBXunrwP0omA6ys3OFqui-xooqfbh7o_MKJLbuGFCC0KuIrMZwnRV8y853Ipy87vjsEGC3JilfAZwiDSmobFioH2pk01bAmh60WRuXybXKdkiRBV7U4EgyZY8TSFTsyNRE2_FQ1sOZy43MTdtLyODHZS2ObJeLNtBdXEvDhwPyu5dMRJGhcjcCenUDlSKcr00kawHKlalIg5Kq_Fo8UFEM19_LRU2KSjTH3wxYzFZmVA_zAg1rFGu6g6elruPhe6uPcIK9WQ2zsWDOu_9ySKm64eMwSKRi8dem15LJBRlYqVi7d0hM1CeKUD_pNj31_TvBtQZGohyRiXQQADhFcXYnSSqiUCqdG-dWkXHkKBeyo3O4KFxLLNHOs4zA9swsj74rROrfC9Ve4OKt6X0LMVKExJX4vo-VZ3VbjQKOWx-ftEalAxY2XBQ9_RfFx96EystzYHFjKSn9S5OlLa35nR3gtI6_KcK6KYkAlzeIZzitSHbP7625OxbWN_esThff7i6uzcPiQo1WQP89dh48f2yqcm2QxHTUsPXz7CmWH7zHTWSXnNCIevZggPcvRFxa-2VLVMDuVY0R372fTdNj1JnTLUH98IEdVsTsuD5CIBt0j-7Oz7nXmEVk9frxfjRNaQCsOlLp433aRj3ErvV_Zvo3WTqn2Wb5_.nK1ZTdZqlUJ2wQIBRTcMrF-YVtb2m1XWLAzpZQ165YffSd7mAQNIrjxh27CmNJoBeDnbkQ2zxWyvbUoVlIxwpPVdWQNN-lymSkRUaOEpzoUzjBQ3LEj1Sj1Xyeqfa2fjFT9zUYR1q4uGrHRYUZI8DMAk9WPv7_VW3P2nbOrwk-eG6lGBecT1PNnhWexJsfT4zxhRvQLDerzpj_pBGNv0F8ZnMqRY8crcBJ3AuSr1pkGtom7740-ITGdxn0uP88px7biw8fxKs1skKhZb2ufCPi8D52t902ND-hffue_vZuOtYSm9A9VxY0Q5C5q1O_GEDR2tLC0jgsdHdH95_8h_AhsMmsRkSGwzMbuGweUxaKDJIlt4MVtE86ovraHz2kBSgKYOlL65Tvg7CbB9SxHmrgAz2SNi6OSt0Ea5QAoMc8yebAap8kwl3ZE2t1wi3giJxs8XQWBRWGfBtxWovDTWxnVcvbU4tm8SBjiPw7weaEIpoBdyfMWXqMt6e4IyvpSyakiuBpQczkP8yUNHI2P4qMYfuMU5BwG1-1SSekc2CorUOthmECqgF_lS8xNGGEdsmVzTOx3z-v9fWACoT2S0jeWIefN8qlo2vBxpiWIvVNG7QINC5SwUd2Qnc1MwJXcYd-z5CwlXN-jnQbM3DKyU8u9sc7WctSpnGVylBz_6mfVuhyXm3geee0ejHxQHKKZPRZgoQMvOngg6Q2kN1tjaykK1QvvKAd99kTqLPt2J-BtC69inXoi1FeFPuyIeSen4EZqOSVRA-MOAz4bSb5wDtqREBRP22WAy6wcQKvf9vj3N6T0DeWd2uvxTDr53iAP5iiOvGEO-bEzQH1ovCj_p8bYPKUyy3ehiuDxBUFBrXTt37XtK56NghNH3oyiZFjfPI_xejsg-y33p33pZOxuK8HbPh2pvAUFwd0Fb_qR8rSpSrctT9sgW-u5WyL7_562xEx-FXIBifktJFgUB6uUolwuJ1kVaemP5fdDZnn0HQ-WeHtOI42JU4_ZGD99c-3SB56eVVRwi8o_rQ74b1qWeUtd6pYHaitqHC_UOAqGqDT1Si_NbiRMIOHKTXER5LLLOYZXu3sx9MbktlsAWshh4p9JQp9it52XlXO7Q44Eah5F0vH_u7mAyeHA7Cm0E1mpqdCGDvUTrFrTBuMRdapU2KVvh-KoNGAmUQWX4tMpzjn4OulqqKrWOGVDJzuFIWVOSIWq61PixGhz2Gc7lKvANgx1TtnyctRogkwOK2DYQFNxO0_KTLbq32miHE9pcJQEBKtVnR5qk7zSmXBpel-pD066u37Xj7nyV6cxykjosn9Ys6RRtPSwkKE3lkZMsluke8IEugq5QgqIf_4VCqE-iPgciko9YvyIw7DBqP3CPa5rghhxpA-RYmuVpvMTB7tbtPXBRl0E3vYya2S5YroU6rUM9acqf90BGv0Fq_36WDIulUon07aSHlbYJTqmfGzqymWIZmXNt2jS-VSUOpNMzheTzC2ygg4gqxZD7SKV9CSONy8hJeFMMs87QpvHG5mJ70SwShaJbnk3DiNh8FBgFdz6MwdIS2CQ33A0oUAnE6fgIwXq4Brtaf46E2ZvmlrkOPnE2quuY-VtTPGQ3OENxZM6ZyrOKeAruUqbl5SyTSTlO_JfUIBNQWwMb0_5-nEbJCLmKGxSeQTJj6ZUgHhi-tJQ4iDp2RPl56ZOHbPBnGBqlz0N4kJ3LLCkFqx9XGWiNrwEeTaaF1A0n_FSZc5kjphetrOXxeWSHlJFz-krcUSw6amer5vCa6BP8ZRurTGhh9HSJWMbkOuOBaexPkNr3fbgalSS9XovGIW44X2lPDFpYS_T8Wv_EgpIHbVxO2GUV0Szpl2kiBWuenpCMr-ih1wXWxiOJQDFgXhWEAHICzB7irlP3yJIBiDQl31AEYxKbSMfBgmQgkNwaoe8Xfm-7Mrj32fmfqpiGKP_WSMi79Z_ZOiwnrPT4h9okdX9y13ylRtSvOfL1-8X4bJgswwHUSHnnWmrO1XRUW0UX0ZRkuZrbo0F9Q1tcjUpJZTY2jkPR7-bVcUVOJIFFTBvUljYc3uFdE1fzdKo9UVByJ7VnCeSqZRPxfqW2GySTSej0SKyqSfctN-4t-ABgcx8YB-oY2qRYTaKGd0O-WwChIkizOkfe9TC6n_Y5z1mSCKMOWVnijy5gGjnfvuVYbRLiXtjWcAIeTx7gr3Ro3fVgn98R5kT6H-hV6cJitD3ch79cSyeDkrq80pzzTPavGcDvvmf1ggdoUnEDaur6gnOZem-VyN3LsN5LMWg7AEde8Tx4AAbwyYfMITxWJ0x5IzrLZ-xFuPEMJkxTQ6wy5T0olbSdBhFJULrvVGAc4W0uYk8CzsUAOQxn6HJ2pHecAN63vnAn9jS2MnN-knqtpMbwyR2J8Rov-HaWlxL5Xuf6oCiF55yzGCoeWuFxPpFlREubBImDbUtxse4CBDeYkzKk3VGLVt8RZdZzNWgKDNlO_wagrbSIcS-30Tv1nY0PKV1gT2AF5gOMt3zDU3TXBDNbtca86Ew64Vmr_vtRHvMp6Gf5OFEMR2184hA6ss2GrK5SRQhyitSPkSjuGLABHEelMP4-4HiHhQ16aILZGRAinKwdu2jAoJ83n6re2z8bnKrMrj1jiZGZFU5ZvcS1yzyNBaaBBz2QY8Ux4fUgzL2CQk9tREqwjjXwsjNHPCZvFkWSY1At-aN_QV8VEJWIqhOb2nSsntH1jvE1R2SPrbOoIYMmT6iBBlBvaiqB9z0RFKMPMM3ShVGcDVf3YvAMb7KJSU0iMsK_gmKZQRinS99WWxZ5z3JxSjDgvJ_SxdxX5j8XogxPpmcmb0Wh7KmNMAGoXmsPKf9RwFcuUMk_mIqxnZc7murXiM4eVDu_ij6brlXdJWf5bS047VuAruNUW1kV6m-6mHQ0xTZMTiUWcr893tYL4GyMZIICl8t5lV326ROZ_jB-8mwIhz5eh7YPjAEWJHmu6vosf9HdqZb8hO-91CTRkud46efCzhcAq-afT5DJ4M4-WdCBW6IuBdzGqJh5ZR7KZPnStcy0RMMUaLgdKRDw1B9SqYzd8bI1suqXRy2Ns7mwwX8fbq1GkK-J6vHuy75M2svjXXDV2wzspzF6MyWDq75Fr93TZEMPv-2YNa1FvE_KeSZzy9P50vrd_ZP2bbFiTUEvlRwjWP2mQSiCNkAPJv0zKgCIPmhx50cKvox4fpx2t1m3MjtM4TnbO1n9jMad0vLEEbWeap-HK6iYakpuOFHtcyBVo3NlbZUtD_Loq94WE6sXh9UZQBnhthxv6PNfwCVF2cRQZTUkvSfnc15b4YqH5S683Ywtn2FkIz9-99YmycavxSqdAUylQvoO-2tJfLWqGpl0W8D9NawJLNtHZzx-iRmFL4RlWAy2T-MKulvep39bTj5osJTcRObPOEEO_bys7Lh2DHtyfZaxtz0Sp_X0kw1Cp4ypMKjkwN7fkFws2WJFG0et1d_ACphk7ZyQGeJFuKu0_unwNrBQN-qMAqhIovQZPvzmxd0pS70odD416N2pdVQjhUEOcp17qbvGZedhcZJqR09T1NjeX7CqNsUwi7Fz5iCGMGSA-6k3lrwY_MIpKActI6XZWuT-P6_oO8rM3YXVG0TEtF0ZhzWJqE61TFOJbhiB0_077C8EkMvW3EP5FO-KgCjPAksOJpiwpMdrYRK4vtasQZ6nNxvfvhHO3mGeaVLMsU12fvWTfAMRn8JclRdJkIlB2XqTwpZksg7sNBFc0ZvDaRtqtH1RCwWkw-r8rtOUpqzLCvSF7MCMSj6uK1p4XG83n_zKyHcDjuEsn4ntjz7abOyOiI5vR9u3kxM7tnT3kLeKc04hved0LFr2BakZciTIUzfl7UfZHJr-W5_BujQ2armoGVs5oMWHAXq7aQDBW3d46KJ4_DrchoEvu-0WBV7G2c2QUwMRyy722ilKdjaIK7xkDcTZIc1AnkBKo_5L-z3MKhDfJ-lCTRepsApjcquUbv2nanT6dzd99Sz2V65kqUtcQMPNBI1pJjZM9W7gCeC-Y6US36_sHPSS0-A29IQV5x-5_5TueYdJiPok7RTh8WSMKHhmMbwrhcFPopGhbt09yebLz7KFv0hgnwvm2Xb3vgtl3EBfnS-TlphT56stFQQe8fX18OZBPtfU-XJCyx_aIkhcIyrprW9DleJpW88e0K4H3hjlfqNZevAA99djo2AITnKeopqiX_3YIZC9mMez7xkEy7gk1ousqR61eIQ6KhhT40NNC_KgHAfOrQ5jLOo5CjOgUDxOGEyITsdlWUW63EJs42Y69ttZ3QQl9QsqLUxjd2AYIOfsU09BOG4wc_NijTKRYuzCGlBOcuBLAlg85lT1Lxfzt_ONykE8Vr4ntxILJuWPgvmdnJCXb4nKR9SgXYhZpLw-9oXY8T1Y4SpXxp3Nkf51QWRlRyCFvETRwuuJX5vIVj7Kcc2o7LGFEye9Mpnjyc6hcZCW66N2HxrPN8bffAi7WneuuIuRG1GApo8GhVZT4xpI0PJws7UZNBEeDjIYApxJ-eS1WKt9t7I4OWgBC98SDgLD7iaV1CtBaxnIDufPKQS_fCPiIJ63SsTgeIetdNRt4eGiU4cJys20bBdO51VBphOubIkE_ZYiXOnzrGBs9GdBXTwyDUCr542C7thhV6VvwTlsJgwiAHY_cI6Att8XKkLS6pVfMTwU9pMGHC3CdM5_itnh0F5WibBrbIwi_IF15aNw7sO9YEDvKrKnYF0vXkjfPAA1hCCoq1E18OTudBgtASVz4-IC8zIsDCBWDQzI5FKKkfWDVBY5-Ty7YIeGeHuxchw4IEkWfg3rKdxAexSGTHDx-ii_eI2A7Wve_HE7yDBfHLkJIIYPjasqTSbNRxW4pQlLQvz-Vm-DsP9cuL5oP-W6oSHvWbyRSiUz45FQqkux-bZx47cAOPpFOdmX_wNkiFoTkQeeOv2Qyt7kEnkP-04BL6t-QD2zRoX7Je_Ws8SuKcEp3iQU6OXxxN1CZlJiPmmKxn"]
}
```

OATs are just JWTs with one or more OAAs specified in the `assertions` property.

### Nested like Russian dolls...

`ORT ( OAT ( OAA ( OAG ) ) )`

The _OAA_ is sent to the _Resource Provider_ so that it can see the user accepted the _OAG_ and take provisioning
and configuration actions.  Once this is done the _OAA_ is ready to be tucked into an _OAT_ and used to gain access
to the resources.  `Central Authority` can have the user's client POST the _OAA_ to the _Resource Provider_'s OAG
acceptance endpoint, or it can POST the signed _OAA_ "irt" (in response to) the _OAG_ using a backchannel process.
In any case, the _Resource Provider_ needs to see the _OAA_ before the grant expires (specified by the "exp")

The `Central Authority` unpacks the credentials stored in the grant by obtaining the session key, decrypting it
with its private key, and then decrypting the credential payload.  It then feeds those credentials over a TLS 
secured connection to an agent running on the _Resource User_s host.  The agent uses native utilities, ssh, fuse,
mount.ceph, mount.nfs, what have you, to configure that access.

The agent becomes a watchdog, remaining in constant communication with the `Central Authority`.  Watching for 
revoke actions, keeping sessions alive between laptop closings and openings, intermittent network availability, 
and providing us with debug output to improve services.

## OSiRIS Access Assertion Management

A web interface will be included as part of `oakd` that allows for
 * Listing and managing OAAs that belong to you
 * Lightweight workflow/approval queues for _Resource User_s
