---
parent: Frequently Asked Questions
---

# What is xip.io/nip.io?

CluedIn uses multiple custom ports and subdomains for organizations.
When running locally this can incur significant setup with editing of hosts files and dns entries.

[nip.io] is a wildcard dns service that removes modification of the hosts by
redirecting requests back to the specified host (in most cases `127.0.0.1` - the machine making requests).

## Nip.io replaced xip.io

Early versions of _Home_ used `xip.io` as a wildcard service but this is no longer available.  For new environments created using _Home 3.2.3_ and up `nip.io` is automatically used.

If you have a previous environment, you can update to `nip.io` using:
```powershell
> .\cluedin.ps1 env <name> -set cluedin_domain=127.0.0.1.nip.io
```

[nip.io]:https://nip.io/