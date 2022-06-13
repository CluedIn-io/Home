---
title: down
parent: v3.3.2
---

# down

Terminates a running instance of CluedIn.
{: .fs-6 .fw-300 }

Running `down` will stop all containers and persisted data.
The images themselves will not be removed, so this command
can be used to effectively clear out an instance, ready to
run again from a clean state.

## Syntax

```
down [[-Env] <string>] [-KeepData] 
```

| Parameter | Type | Required | Default Value | Description |
| --------- | ---- | -------- | ------------- | ----------- |
| Env | String | false | default | The environment in which CluedIn will run. 
| KeepData | Flag | false | False | If set, data for services will be retained for future use. 


