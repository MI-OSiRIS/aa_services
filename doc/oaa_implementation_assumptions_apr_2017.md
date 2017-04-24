OAA Implementation Assumptions (04/2017)
========================================

 * **Central Authorities** shall be able to act as all parties (Requestor, Resource Authority, Trustee, etc) insofar as they currently exist in this scheme.  They are to have "administrative" privileges, which means if they so choose, they may create and sign a request, the corresponding grant, and the final OAA without any third party's involvement.  This is required since we are currently in a "manual configuration" state and have to support being able to have admins grant access tokens.  It should be a goal to remove Central Authorities as soon as possible, especially once the project moves out of OSiRIS.

 * OARs should be able to outline multiple requested services which can in turn be provided by multiple Resource Authorities (RAs), and an OAG may offer many services but only from one RA.  If an OAR is satisfied by multiple RAs, an OAG must be issued by each RA.  Multiple OAGs may end up in a single OAA, however.  The alternative would be to pass around the first OAG received to gain signatures / counter offers.  Making it one OAG per Resource Authority makes the process much cleaner.  We can present to the Requestor what services have been pledged and what services have not yet been acquired based on their request.  Plus it avoids the problem of slow RAs seizing up all resource acquisition actions.

 * To avoid the duplication of data, and the potential for things to require periodical synchronization, we will use LDAP as the sole data source for OAA, including entities, organizations, and tokens (perhaps excepting potential optimizations like taking advantage Ceph Metadata (this is being reviewed)).  We'll only start using an RDBMS if it becomes unfeasable to provide absolutely necessary functionality without using one (I removed my code's relational data model with this commit).  And if we do, we always have COmanage's MySQL instance already running.  That said, I don't foresee us needing to go that route.

 ## Token Roundtrippability 
 
 Due to multi-level attribute and sub-object opacity, the deserialized form of the various tokens will look different to different entities, and the token will be represented in three different forms.  
 
  1. As a string in <hdr>.<payload>.<sig> format
  2. As a deserialized JSON structurea
  3. is as it is represented inside of an LDAP::Entry object.  
  
 It is imparative that they are all always one method or function call away from being the exact same string at any point in time.  For performance reasons we are going to have to rely on the `osirisTokenThumbprint`, and quite often at that.  This means canonicalization, sorting alphabetically of keys and values, and eliminating non-essential whitespace **always**.
 
 There may be more than one implementation of the token parser/serializer written as time goes by.  No matter who deserializes the token, and no matter what source they use, and no matter what the deserialized token looks like to them, when it is serialized it **MUST** be identical to any other entity's serialization of that same token.  I believe this will be non-trivial, and so it is important to keep in mind as implementation progresses.  I will write a very comprehensive test suite for the parser and serializer as part of this and encourage anyone who is wants to write their own parser/serializer to take a look at the test suite for ideas on where/how you can get hung up on this issue.

## Admin Tools

### Resource Authority Management Page

This tool allows administrators to add new resource authorities.  In the future, it might be harmless to allow anyone to add a resource authority, provided that it meet certain criteria and they open it for inspections, etc.

Resource Authorities MUST
 * Have an RSA keypair, the server side can generate it for you, but the RA must take ownership of the private key
 * Specify their `osirisKeyThumbprint`, `osirisSigningCertificate`, and `osirisEncryptionCertificate`
 * Run a St.P Endpoint (gateway, St. Peter, get it?), publish the URL to that endpoint and have that service return values that match the values provided for their keys and thumbprint.
 * They should also have specified organizational affiliations

## User Tools

### Access Overview and Management Page

 * Allow user to browse existing resources belonging to their group
 * Allow user to access resources via web objects / receive instructions on how to access that resource via their client
 
### Resource Request Page

 * Browse types of resources offered by OSiRIS
 * OAR Composer Tool / Form that allows them to set the parameters, timeframe, and metadata of their engagement
 * OAG Review Tool (also the pre-OAR-send review page), allows user to review the resources that were granted and under what terms.  The differences between the OAR and what came back in the OAG are highlighted for the user.  This page will have two action "buttons" on it.  "Accept" or "Refuse".  
 
If the OAG is refused:
  * it is logged to a refused OAGs log
  * it and the corresponding OAR get deleted from LDAP (in all their forms)
  
If the OAG is accepted: 
  * the OAA is created using the data from the OAG, and and is stored in LDAP, both as an osirisToken/osirisAccessAssertion in ou=OAAs, ou=Tokens, dc=osris, dc=org and as a string inside the requestor's osirisAccessAssertions attribute. 
  * the OAR and OAG are deleted from LDAP (in all their forms) perhaps they are written to a log file of successfully accepted requests/grants for review, analysis, and statistics.

## Flow

### Principal Authenticates via their IdP
 
We know who they are, they sign in, they are also in LDAP.  
 