---
parent: v3.5.2
title: pull
---

# pull

Pulls the latest container images from the container registry.
{: .fs-6 .fw-300 }

Docker images may be refreshed using the same tag. Run this command
to ensure you always have the most up-to-date version image for
the specified tag.

## Syntax

```
pull [[-Env] <string>] [-Tag <string>] [-TagOverride <string[]>] 
```

| Parameter | Type | Required | Default Value | Description |
| --------- | ---- | -------- | ------------- | ----------- |
| Env | String | false | default | The environment in which CluedIn will run. 
| Tag | String | false |  | The CluedIn version tag to use for all services.<br />Defaults to the setting in the environment. 
| TagOverride | String[] | false | @() | The CluedIn version tag to use for specific services.<br />The names or services match those reported by docker when starting CluedIn<br />e.g. `-tagoverride server=3.2.4-beta,sqlserver=3.2.4-beta`<br />Defaults to the settings in the environment. 


