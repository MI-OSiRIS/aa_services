Client Auth
===========

The high priority client use case we have in mind is for `mount.osiris`, or, a tool that mounts an OSiRIS file resource that the user has access to.  Two approaches immediately come to mind for getting OATs to the clients that wish to access OSiRIS resources.

## Common Flow

Before diving in to the different user interfaces, I will first outline the aspects of the authentication flow that will be the same between the two approaches.

### Client Watchdog / Facilitator Daemon

When the command starts up a daemon spins up and begins listening on a socket.  The watchdog will be aware of the state of the action and communicate back to the GUI or Command Line interfaces via IPC to prompt and obtain user input where appropriate.

The `Client Watchdog` will run for the entire lifecycle of the mount, and will facilitate the tear down of the ceph mount when it is unmounted.

### Locally Generated Client Identifier

Since it's trivially easy to unpack bundles and grok Perl or Javascript code for an OAuth2 `Client ID` and `Client Secret`, we will instead generate a OAA `Client Identifier` from data about the remote machine.  It will likely be hash of properties containing the CPU's Unique Hardware ID, the currently logged in user, and the output of `uname -nprsm`.  Something like this would work on Linux:

```bash
    echo $(sudo dmidecode -t 4 | grep ID | sed 's/.*ID://;s/ //g')\
         $(ifconfig | grep enp0s31f6 | awk '{print $NF}' | sed 's/://g')\
         $(uname -nprsm)\
         $(whoami)\
         | sha256sum | awk '{print $1}'
```

If they log in as a different user, get a new network card, switch operating systems, etc, then we get the desired effect of this ID changing.

### Preauth-Request

The first thing the `Client Watchdog` will do, is issue a request to the `Central Authority` to register itself.

## GUI Interface

A simple [Electron](http://electron.atom.io/)-based application (think Slack client) that can be packaged up with all the code necessary to handle the Authentication flow.  The GUI interface has the added benefit of allowing an authenticated user to select which resource(s) they want to mount, most likely via a resource selector page rendered by the `Central Authority` after SAML2 login.

## Command Line Only

