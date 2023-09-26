---
parent: v3.7.4
title: data
---

# data

Identifies and clears data for an instance of CluedIn.
{: .fs-6 .fw-300 }

When an environment is started, one or more services may store data
outside of the container so that it can be used for future scenarios.
This command enables identification and removal of persisted data.

## Get Details

```
data [[-Env] <string>] 
```

Displays information on the persisted data for an environment.
e.g
```
> .\cluedin.ps1 data
Name          Size      Items
----          ----      -----
elasticsearch 0.49 MB      56
neo4j         0.91 MB      43
sqlserver     240.06 MB    32
```    

| Parameter | Type | Required | Default Value | Description |
| --------- | ---- | -------- | ------------- | ----------- |
| Env | String | false | default | The environment in which CluedIn will run. 

## Clear All

```
data [[-Env] <string>] -CleanAll 
```

Forces all persisted data for all services to be wiped from disk.    

| Parameter | Type | Required | Default Value | Description |
| --------- | ---- | -------- | ------------- | ----------- |
| Env | String | false | default | The environment in which CluedIn will run. 
| CleanAll | Flag | true | False | Clears all data for all services. 

## Clear Service(s)

```
data [[-Env] <string>] -Clean <string[]> 
```

Removes the persisted data for one or more services.    

| Parameter | Type | Required | Default Value | Description |
| --------- | ---- | -------- | ------------- | ----------- |
| Env | String | false | default | The environment in which CluedIn will run. 
| Clean | String[] | true |  | Specify one or more service names who's data is to be cleared. 


