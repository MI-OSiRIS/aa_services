Client Auth
===========

The high priority client use case we have in mind is for `mount.osiris`, or, a tool that mounts an OSiRIS file resource that the user has access to.  Two approaches immediately come to mind for getting OATs to the clients that wish to access OSiRIS resources.

## Common Flow

Before diving in to the different user interfaces, I will first outline the aspects of the authentication flow that will be the same between the two approaches.

### Client Watchdog / Facilitator Daemon

When the command starts up a daemon spins up and begins listening on a socket.  The watchdog will be aware of the state of the action and communicate back to the GUI or Command Line interfaces via IPC to prompt and obtain user input where appropriate.

The *Client Watchdog* will run for the entire lifecycle of the mount, and will facilitate the tear down of the ceph mount when it is unmounted.

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

The first thing the *Client Watchdog* will do, is generate the unique *Client Identifier* and issue a request to the *Central Authority* to register itself.

A simple GET or POST request should suffice, but we could also use [JSON-RPC](http://www.jsonrpc.org/specification) as outlined below.

`https://comanage.osris.org/oak/client_register/?client_ident=<sha256 hex>`

The registration service would return a text-only body with a short-lived human-typeable token to be presented to the user by either the CLI interface or the desktop client interface.  A very simple body could look like this.

`HW9X3`

Or, using [JSON-RPC](http://www.jsonrpc.org/specification), we could send this to **https://comanage.osris.org/oak/jsonrpc/**:

### Request
```json
{
    "jsonrpc": "2.0",
    "id": "d2ee1f3b-9f2c-4900-b407-90bb4ccae9fd",
    "method": "client_register",
    "params": {
        "client_identifier": "ae004f693de56bc80b44230fdce44e6cc680a5790bbd0be6566e42bef8f91c84"
    }
}
```

### Response
```json
{
    "jsonrpc": "2.0",
    "id": "d2ee1f3b-9f2c-4900-b407-90bb4ccae9fd",
    "iat": 1484318853,
    "exp": 1484319153,
    "result": "HW9X3"
}
```

The *Central Authority* keeps track of both the remote host that created the connection to its' service, as well as the *Client Identifier*.

## GUI Interface

A simple [Electron](http://electron.atom.io/)-based application (think Slack client) that can be packaged up with all the code necessary to handle the Authentication flow.  The GUI interface has the added benefit of allowing an authenticated user to select which resource(s) they want to mount, most likely via a resource selector page rendered by the *Central Authority* after SAML2 login.

While technically the [Electron](http://electron.atom.io/) platform is just a re-skinning of Google's open source [Chromium](https://www.chromium.org/) browser project, consideration should be given to our policy of _not accepting user credentials into OSiRIS-branded software_.  This policy not only makes the OSiRIS project more secure, but it promotes sound security practices for end users.

## Command Line Only

