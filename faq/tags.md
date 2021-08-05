---
parent: Frequently Asked Questions
---

# What tags can I use for versions of CluedIn?

CluedIn is built from a collection of docker images.  Each image has multiple _tags_ to make updating to future versions as simple as possible.  You can either specify the _full_ tag to target a specific version, or specify a _floating_ tag which makes updating to the next bug fix version a little easier.

## Working with pre-release versions

Pre-release versions have a _floating_ tag that contains a pre-release label, e.g. `3.2.3-beta`.  You can use this to consume the _3.2.3-beta_ version of all services.
```powershell
> .\cluedin.ps1 env 323 -tag 3.2.3-beta
```

> You can now also update to the very latest beta versions by running `.\cluedin.ps1 pull 323`

If however you need to consume a precise version of a specific service, you can use the _full_ tag for that service.  E.g. if we want to set _server_ to use `3.2.3-beta.3`
```powershell
> .\cluedin.ps1 env 323 -tag 3.2.3-beta -tagoverride server=3.2.3-beta.3
```

> You can still run `pull` to update the other service versions, but _server_ will stay on `3.2.3-beta.3`

## Working with release versions

Release versions do not contain a pre-release label, however you can still float on the _patch_ (final digits) of the version:

```powershell
# Set the version to 3.2 for all services
> .\cluedin.ps1 env 32 -tag 3.2

# Update to the next patch release - this could be version 3.2.4, then 3.2.5 etc
> .\cluedin.ps1 pull 32

# Pin server to version 3.2.3
> .\cluedin.ps1 env 32 -tag 3.2 -tagoverride server=3.2.3
```