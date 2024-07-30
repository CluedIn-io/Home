---
title: check
parent: v4.3.0
---

# check

Tests environment configuration is acceptable for CluedIn.
{: .fs-6 .fw-300 }

Performs a series of checks against the host machine for required services (e.g. docker),
performance concerns (e.g. available memory), and validates environment configuration
(e.g. port availability).

## Syntax

```
check [[-Env] <string>] 
```

```powershell
> .\cluedin.ps1 check

+----------------------------+
| CluedIn - Pre-Flight Check |
+----------------------------+
Installed Applications
[1/3] ✅ » PowerShell : 7.1.1 / Core
[2/3] ✅ » Docker : 20.10.7 / linux
[3/3] ✅ » Docker Compose : 1.29.2
Available Ports
[1/23] ✅ » CluedIn UI : 127.0.0.1.nip.io:9080
[2/23] ✅ » CluedIn API : 127.0.0.1.nip.io:9000
[3/23] ✅ » CluedIn Auth : 127.0.0.1.nip.io:9001
[4/23] ✅ » CluedIn Jobs : 127.0.0.1.nip.io:9003
[5/23] ✅ » CluedIn WebHooks : 127.0.0.1.nip.io:9006
[6/23] ✅ » CluedIn Public : 127.0.0.1.nip.io:9007
#...
```    

| Parameter | Type | Required | Default Value | Description |
| --------- | ---- | -------- | ------------- | ----------- |
| Env | String | false | default | The environment in which CluedIn will run. 


