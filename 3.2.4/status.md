---
title: status
parent: v3.2.4
---

# status

Checks the health status of a running CluedIn instance.
{: .fs-6 .fw-300 }

Requests the health status of a running CluedIn instance,
reporting back a red/green status for each hosted web service and
each data persistance service.

## Syntax

```
status [[-Env] <string>] 
```

| Parameter | Type | Required | Default Value | Description |
| --------- | ---- | -------- | ------------- | ----------- |
| Env | String | false | default | The environment in which CluedIn is running. 


