Client Auth
===========

The high priority client use case we have in mind is for `mount.osiris`, or, a tool that mounts an OSiRIS file resource that the user has access to.  The approach below is modeled after the [OAuth for Native Apps IETF draft](https://tools.ietf.org/html/draft-ietf-oauth-native-apps-06).  The authentication scheme described here differs slightly from the flow described in [Figure 4.1](https://tools.ietf.org/html/draft-ietf-oauth-native-apps-06#section-4.1) of the OAuth Client Auth draft, but is similar enough.  The differences mostly stem from the fact that user participation may be required to nudge along the process.

### 4.1.  Authorization Flow for Native Apps Using the Browser

```
  +~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+
  |          User Device           |
  |                                |
  | +---------------------------+  |                     +-----------+
  | |                           |  | (5) Authz Code      |           |
  | |        Client App         |----------------------->|  Token    |
  | |                           |<-----------------------|  Endpoint |
  | +---------------------------+  | (6) Access Token,   |           |
  |    |              ^            |     Refresh Token   +-----------+
  |    |              |            |
  |    |              |            |
  |    | (1)          | (4)        |
  |    | Authz        | Authz      |
  |    | Request      | Code       |
  |    |              |            |
  |    |              |            |
  |    v              |            |
  | +---------------------------+  |                   +---------------+
  | |                           |  | (2) Authz Request |               |
  | |          Browser          |--------------------->| Authorization |
  | |                           |<---------------------| Endpoint      |
  | +---------------------------+  | (3) Authz Code    |               |
  |                                |                   +---------------+
  +~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+
```

## Common Flow

Before diving in to the different user interfaces, I will first outline the aspects of the authentication flow that will be the same between the two approaches.

### Client Service Daemon

When the command starts up a daemon spins up and begins listening on a socket.  The watchdog will be aware of the state of the action and communicate back to the GUI or Command Line interfaces via IPC to prompt and obtain user input where appropriate.

The *Client Service Daemon* will run for the entire lifecycle of the mount, and will facilitate the tear down of the ceph mount when it is unmounted.

### Locally Generated Client Identifier

Since it's trivially easy to unpack bundles and grok Perl or Javascript code for an OAuth2 *Client ID* and *Client Secret*, we will instead assume the client is public and generate a OAA *Client Identifier* from data about the remote machine.  It will likely be hash of properties containing the CPU's Unique Hardware ID, the currently logged in user, and the output of `uname -nprsm`.  Something like this would work on Linux:

```bash
    echo $(sudo dmidecode -t 4 | grep ID | sed 's/.*ID://;s/ //g')\
         $(ifconfig | grep enp0s31f6 | awk '{print $NF}' | sed 's/://g')\
         $(uname -nprsm)\
         $(whoami)\
         | sha256sum | awk '{print $1}'
```

If they log in as a different user, get a new network card, switch operating systems, etc, then we get the desired effect of this ID changing.  The purpose of the `Client Identifier` is to uniquely identify the client with as much meaningful context as we can.

### Preauth-Request

The first thing the *Client Service Daemon* will do, is generate the unique *Client Identifier* and issue a request to the *Central Authority* to register itself.

A simple GET or POST request should suffice, but we could also use [JSON-RPC](http://www.jsonrpc.org/specification) as outlined below.

`https://cm.osris.org/oak/client_register/?client_ident=<sha256 hex>`

The registration service would return a text-only body with a short-lived human-typeable *Preauth Token* to be presented to the user by either the CLI interface or the desktop client interface.  A very simple response to a REST request could just contain the *Preauth Token* as plaintext.

`HW9X3`

Or, using [JSON-RPC](http://www.jsonrpc.org/specification), we could send this to `https://cm.osris.org/oak/jsonrpc/`:

#### Request
```json
{
    "jsonrpc": "2.0",
    "id": "d2ee1f3b-9f2c-4900-b407-90bb4ccae9fd",
    "method": "client_register",
    "params": {
        "cid": "ae004f693de56bc80b44230fdce44e6cc680a5790bbd0be6566e42bef8f91c84",
        "ort": ["<ORT1>", "<ORT2>"],
    }
}
```

#### Response
```json
{
    "jsonrpc": "2.0",
    "id": "d2ee1f3b-9f2c-4900-b407-90bb4ccae9fd",
    "iat": 1484318853,
    "exp": 1484319153,
    "result": {"preauth_token": "HW9X3"}
}
```

#### Or, in the case that one of the stored `ORT`s passed muster
```json
{
    "jsonrpc": "2.0",
    "id": "d2ee1f3b-9f2c-4900-b407-90bb4ccae9fd",
    "iat": 1484318853,
    "exp": 1484319153,
    "result": {"oat": "<OAT>"}
}
```

The *Central Authority* takes note of the

 * ip address of the remote client
 * *Client Identifier* of the remote client
 * *Preauth Key* issed for the client

The *Preauth Key* is good for 5 minutes at maximum, if the authentication process does not finish by then then the authentication attempt is aborted, and must be restarted.

## GUI Interface

A simple [Electron](http://electron.atom.io/)-based application (think Slack client) that can be packaged up with all the code necessary to handle the Authentication flow.  The GUI interface has the added benefit of allowing an authenticated user to select which resource(s) they want to mount, most likely via a resource selector page rendered by the *Central Authority* after SAML2 login.

While technically the [Electron](http://electron.atom.io/) platform is just a re-skinning of Google's open source [Chromium](https://www.chromium.org/) browser project, consideration should be given to our policy of _not accepting user credentials into OSiRIS-branded software_.  This policy not only makes the OSiRIS project more secure, but it promotes sound security practices for end users.

With that in mind the GUI interface would likely behave identically to the command line interface.  The key differences being the ability to create a link that automatically opens the browser window with the *Preauth Token* passed in, an improved GUI resource selection interface, a preferences panel, and a status screen summarizing the currently mounted OSiRIS resources with statistics, and dismount options for each.

## Command Line Only

This interface will be kicked off with an incantation that looks something like this:

`mount -t osiris cephmon1-wsu.osris.org:/projectname /mnt/projectname`

Once launched, the main process would remain interactive with the user, fork the *Client Service Daemon* process, and connect to it via its UNIX socket.  The *Client Service Daemon* process will parse the local cache of `ORT`s and perform the *Preauth Request* in the background, including the `ORT`(s) that match(es) the resource the user is trying to mount.  If the *Central Authority* agrees that the `ORT` is <sup>1.</sup> still valid, and <sup>2.</sup> that it matches the client identified by the *Client Identifier*, it will return an `OAT` which can then be sent over the *Resource Authoirity* to retrieve native credentials, at which point, the user interface completes the **Native Auth** step and exits, leaving the *Client Service Daemon* to watch for revocations, disconnections, and system changes that would require it to reconnect.

However, if none of the `ORT`s were valid, there was a *Client Identifier* mismatch, or this client hasn't been used to access these resources yet (had no matching `ORT`s), then the interactive process will display a message to the user along the lines of:

```
OSiRIS Client Authentication

To allow this client to access the 'cephmon1-wsu.osris.org:/projectname' please 
visit the following URL in your web bowser:

    https://cm.osris.org/activate

And enter the code: HW9X3

Waiting for authorization: <animated indicator>
```

In the mean time the *Client Service Daemon* process opens a WebSocket connection to the *Central Authority*, receiving realtime updates on the authentication process completion.  These could be used to provide feedback to the user interface that progress is being made.  

If IdP authentication completes before the validity of the *Preauth Token* expires, then the *Central Authority* will send a WebSocket message to the *Client Service Daemon* that looks something like:

```json
{
    "event_type": "authn_successful",
    "payload": { "oat": "<OAT>" }
}
```

Since this preauth WebSocket will be opened with the short-lived *Preauth Token*, the connection will only remain open until that token expires.  If the connection dies in the preauth stage, the *Client Service Daemon* will send a message to the interactive UI program instructing it to print a timeout error and exit.

When the *Client Service Daemon* gets this message it should hang up its preauth WebSocket connection and establish a new one using the the new `OAT` inside the `Authorization` header of its next request.  The *Client Service Daemon* should somewhat aggressively try and keep this session open to the *Central Authority* for the lifetime of the `OAT` to watch for revocation events, potential service migration notices, and other important realtime communications from the OSiRIS mothership.

### Client Resource Request Aggregation

The *Central Authority* will keep track of all initiated requests according to the *Client Identifier* using a data structure that looks similar to this:

```json
{
    "70b1160ba504bfcf1a7e4868ccf07070824435137d038995aeb8668572890ef7": {
        "MfrvvgrbF7kvzfHhgqC3DOM_l2YNA2lj": {
            "expire_time": 1484949846,
            "resource": {
                "type": "cephfs-mount",
                "location": "sci45:/more/science"
            }
        },
        "jsNI-1B3zKQ-TEfJlygdbQ3Jt87krEnx": {
            "expire_time": 1484949923,
            "resource": {
                "type": "cephfs-mount",
                "location": "phy02mon.example.edu:/incredible_explosion"
            },
        }
    }
}
```

The *Preauth Token* is derived from the first five alphanumeric characters of a WebSocket session ID.  In the above example, `MfrvvgrbF7kvzfHhgqC3DOM_l2YNA2lj` would be the WebSocket session ID, and so the *Preauth Token* would be `MFRVV`.  The second ID's *Preauth Token* would be 'JSNI1', and so on.  Since there will be one OSiRIS AA *Client Service Daemon* per user, and the deterministic *Client Identifier* includes the UNIX `userid`, these sessions should all be channeled over that WebSocket connection.

Thus, if any *Preauth Token* issued to that *Client Identifier* is used as part of a `https://cm.osris.org/activate` initiated auth flow, the user will receive a confirmation page including details for all of these resource requests, and if confirmed by the user, OATs will be issued and sent along to the *Client Service Daemon* for each request, all at once.

### TL;DR

 * Authenticated `eduPersonPrincipalName` **+** 
 * **Preauth Token** + Matching **Client Identifier** **+** 
 * Review and Final Consent By Authenticated `eppn`) **=** 
 * All `OAT`s (and `OAR`s) matching that **Client Identifier** are issued

### Native Auth

The **Native Auth** step involves taking the credentials returned by the *Resource Authority* and using the native interface(s) e.g. `mount.ceph` to actually mount the file resource.  The `OAT` and native credentials are kept in memory inside the *Client Service Daemon* for the life of the process so that the *Client Service Daemon* can remount resources after connectivity problems, or retrieve new ephemeral credentials if the original credentials expired before the validity term of the `OAT` has elapsed.
