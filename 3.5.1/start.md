---
parent: v3.5.1
title: start
---

# start

Starts a previously stopped instance of CluedIn.
{: .fs-6 .fw-300 }

Calling start will restart an instance of CluedIn
but will not create the containers if they do not exist.
Use `up` to ensure containers are created.

## Syntax

```
start [[-Env] <string>] [-Tag <string>] [-TagOverride <string[]>] 
```

| Parameter | Type | Required | Default Value | Description |
| --------- | ---- | -------- | ------------- | ----------- |
| Env | String | false | default | The environment in which CluedIn will run. 
| Tag | String | false |  | The CluedIn version tag to use for all services.<br />Defaults to the setting in the environment. 
| TagOverride | String[] | false | @() | The CluedIn version tag to use for specific services.<br />The names or services match those reported by docker when starting CluedIn<br />e.g. `-tagoverride server=3.2.4-beta,sqlserver=3.2.4-beta`<br />Defaults to the settings in the environment. 


