---
parent: v3.5.0
title: up
---

# up

Creates and starts an instance of CluedIn.
{: .fs-6 .fw-300 }

If the containers for CluedIn do not exist, they will
be created and started.  If they do exist, they will
be restarted.

## Syntax

```
up [[-Env] <string>] [-Tag <string>] [-TagOverride <string[]>] [-Disable <string[]>] [-Pull] [-DisableData] 
```

| Parameter | Type | Required | Default Value | Description |
| --------- | ---- | -------- | ------------- | ----------- |
| Env | String | false | default | The environment in which CluedIn will run. 
| Tag | String | false |  | The CluedIn version tag to use for all services.<br />Defaults to the setting in the environment. 
| TagOverride | String[] | false | @() | The CluedIn version tag to use for specific services.<br />The names of services match those reported by docker when starting CluedIn<br />e.g. `-tagoverride server=3.2.4-beta,sqlserver=3.2.4-beta`<br />Defaults to the settings in the environment. 
| Disable | String[] | false |  | The services to disable during startup. This allows parts<br />of CluedIn to be hosted in docker, with other services hosted<br />locally or on a different network.<br />The names of services match those reported by docker when starting CluedIn<br />e.g. `-disabler server,sqlserver` 
| Pull | Flag | false | False | When set, the latest versions of images will be pulled first. 
| DisableData | Flag | false | False | When set, the data folder will not be used for reading/writing data.<br />All data will be persisted directly to the running docker image. 


