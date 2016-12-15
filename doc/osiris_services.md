# OAA Services

`oakd` should be reverse-proxied back to via a shibboleth-enabled Apache 2.4 web server, the Apache configuration
for `oakd` should look something like:

```apache
<Location /oakd/>
  AuthType shibboleth
  ShibRequestSetting requireSession 1
  Require valid-user
  ProxyPassInterpolateEnv On
  ProxyPass "http://127.0.0.1:8111/oakd/" interpolate
  ProxyPassReverse "http://127.0.0.1:8111/oakd/" interpolate
  
  # certain Shibboleth attributes should be passed back as headers, it's important
  # that oakd check the remote_address of the connecton to ensure that it's coming
  # from localhost when relying on these as they can be spoofed by other sources
  # if they're coming from localhost though, they can be trusted.
  RequestHeader set "X-Remote-User" %{REMOTE_USER}s
  RequestHeader set "X-Persistent-Id" %{persistent-id}e
  RequestHeader set "X-EPPN" %{eppn}e
  RequestHeader set "X-Display-Name" %{displayName}e
  RequestHeader set "X-Affiliation" %{affiliation}e
  RequestHeader set "X-Shib-Handler" %{Shib-Handler}e
  RequestHeader set "X-Shib-Session-Id" %{Shib-Session-ID}e
</Location>
```

## Oakd Endpoints

`oakd` is the OAA service that runs on the _Central Authority_, the endpoints listed are the full path, excluding
scheme://and.host.name, these are all JSON-RPC endpoints except for `metadata.json`, which does not take any 
arguments and just returns metadata information.

### Endpoints that take bearer tokens or do not require authentication

* **/oakd/metadata.json** - The endpoint from which metadata about this oakd configuration
* **/oakd/token/validate** - Indicates if a passed-in token is still valid in a boolean fashion
* **/oakd/token/refresh** - Given an OAR, retrieves a new OAT
* **/oakd/token/agent_retrieve** - Given an OAA id, OR a resource and eppn, kicks off a process whereby an authenticated
principal may release an OAT directly to an agent process.  If the agent is unregistered with the `oakd` service, then 
this might trigger an email to the eppn or a notification to kickoff the registration process.  If the agent is already 
registered as a `target` wtih the `oakd` instance, however, the OAT may be immediately released, thus serving the request
for access

### Endpoints that require Shibboleth/SAML2 Authentication

* **/oakd/token/retrieve** - Given an OAA ID, retrieves a new OAT for the authenticated user (_requires shib auth_)
* **/oakd/access/request** - The endpoint that users can visit to initiate the _OAR_ process (_requires shib auth_)
* **/oakd/access/list** - Lists OAAs issued for the requesting user (_requires shib auth_)
* **/oakd/agent/authorize** - Given an Agent ID, authorizes a non-web agent to act on your behalf

## StPd Endpoints

`stpd` is the OAA service that runs on a _Resource Provider_

**/stpd/metadata.json**

### Endpoints that require bearer tokens

* **/stpd/token/redeem** - Used to obtain native credentials for a service 
