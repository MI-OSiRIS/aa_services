# OSiRIS Access Assertions

## Assertion Types
* _OSiRIS Access Request (OAR)_ - Issued by _Central Authority_ `oakd` to one or more _Resource Authorities_ `stpd` to provision services and receive an...
* _OSiRIS Access Grant (OAG)_ - Issued by _Resource Authorities_ `stpd` to the _Central Authority_ `oakd` to be included in an...
* _OSiRIS Access Assertion (OAA)_ - To be stored by _Central Authority_ `oakd` and delivered to user agents as part of an..
* _OSiRIS Access Token (OAT)_ (short lived, hours/days/weeks) and / or an _OSiRIS Refresh Token (ORT)_ (longer-lived, months/years) which are stored on client machines and are used as bearer tokens to gain access to resources

## Authority Types

* _Central Authority_ - e.g. OSiRIS `oakd`, trusts InCommon and other IdPs, handles Authentication and authorization for the OSiRIS enterprise itself, and performs some AuthZ.  If `oakd` issues an 

* _Resource Authorities_ - e.g. OSiRIS `stpd`, has certificates and will sign tokens issued by _Identity Authorities_ if certain criteria are met.  This gives resource owners a bit of their own AuthZ power and might come in handy.  This also introduces a point in the OAA issuance flow for provisioning of resources themselves.  Even if access keys are ephemeral, the resources themselves (UNIX Accounts, sudo rights, filesystems, namespaces, and block devices) are not.

## OAA Issuance Flow

### Resource Assertion Request

```
{
    "iss": "urn:MI-OSiRIS",
    "jti": "b724c2c5-0a42-4d0f-9c69-c21e240ac20b",
    "iat": 1473280947,
    "exp": 1473280977,
    "sub": ["ak1520@wayne.edu", "urn:MI-OSiRIS:comanage:1"],
    "aud": [
        "urn:MI-OSiRIS:AfRlV67YnPf-Q-8WpM23B7Ds7vlIJJER", "urn:MI-OSiRIS:hRiHEh-3fCe47Kg0UhMVjx1RRYVsdqDk"
    ],

    // session key encrypted with each resource provider's public key
    // provided in the same order they are listed in 'aud', any sensitive
    // data will be encrypted with this symmetric session key using
    // crypto_stream_xor, with the nonce being the first 
    // crypto_stream_NONCEBYTES of the sha256 hash of the "jti" string
    "sk": [
        "vr77Lv31xJXQPR0pNA63JC4",
        "/02ZGeOePwriwiO6F3r4eok"
    ],

    // an array of access 
    // know how to provision and grant
    access: [
        "read", "write", "admin",

        // but if the 'access' is an object instead of a string consider
        // it 'advanced', and include extra information to facilitate the
        // grant
        {
            // the label is what we call this access (required)
            "label": "shell-account",

            // if present it means only these RPs should consider this
            // portion of the OAR (optional)
            "aud": ["urn:MI-OSiRIS:hRiHEh-3fCe47Kg0UhMVjx1RRYVsdqDk"],
            
            // preflight run to see if resource has been provisioned, if this 
            // code returns 1, then run "grant", if this code returns 0 then
            // run "prov", if this code returns -1 then run "dprov" (required)
            "pchk": ["1+CeZgfwM5DdboGVlrHmK3rashzaLiJf4h7YdlVkdDo6FM0jT4l4K"],
            
            // what to run to provision access (optional)
            "prov": "[zaURai/rvr77Lv31xJXQPR0pNA63JC4am0FS8/gimfv+1LcV"],
            
            // what to run to deprovision resource (optional)
            "dprov": "[zaURai/rvr77Lv31xJXQPR0pNA63JC4am0FS8/gimfv+1LcV"],
            
            // what to run to grant ephemeral access to the resource or to
            // actually perform the action defined by this label (optional)
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
        'monhost:/some/path',
    ]
}
```

### Resource Assertion Grant
```
{
    "iss": "urn:MI-OSiRIS:AfRlV67YnPf-Q-8WpM23B7Ds7vlIJJER",
    "sub": "ak1520@wayne.edu",

}
```
