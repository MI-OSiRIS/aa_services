Configurable Settings
=====================

<table
    <tr>
        <th>Parameter Name</th>
        <th>Default Value</th>
        <th>Description</th>
        <th>Config Level</th>
    </tr>
    <tr>
        <td>preauth_token_length</td>
        <td>5</td>
        <td>The number of alphanumeric characters of the preauth token</td>
        <td>Server Configuration (oakd)</td>
    </tr>
    <tr>
        <td>force_idp_reauthentication</td>
        <td>false</td>
        <td>If true, always send along ForceAuthn="true" with SAMLRequests</td>
        <td>Project Configuration (comanage iface)</td>
    </tr>
    <tr>
        <td>enforce_remote_addr_match</td>
        <td>true</td>
        <td>If true, only accept SAMLResponses that originate from the same IP address as the CSD connection/preauth</td>
        <td>Project Configuration (comanage iface)</td>
    </tr>
    <tr>
        <td>new_oaa_notify_owner</td>
        <td>false</td>
        <td>If true, email the owner whenever a new OAA is issued for their resource(s)</td>
        <td>User Preferences (osiris-agent)</td>
    </tr>
</table>

