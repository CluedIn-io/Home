---
title: env
parent: v3.6.0
---

# env

Management of CluedIn environments.
{: .fs-6 .fw-300 }

Environments allow alternative configurations of CluedIn to be managed
at the same time.

Using environments, you can configure different versions of CluedIn,
configure different packages, validate different imports of data, and more.

## Get

```
env [[-Name] <string>] [-Get] 
```

Displays current variables for an environment.    

| Parameter | Type | Required | Default Value | Description |
| --------- | ---- | -------- | ------------- | ----------- |
| Name | String | false | default | The environment in which CluedIn will run. 
| Get | Flag | false | False | When set, displays information about the environment. 

## Tag Override

```
env [[-Name] <string>] -TagOverride <string[]> 
```

Enables overriding specific services with their own version of CluedIn.    

| Parameter | Type | Required | Default Value | Description |
| --------- | ---- | -------- | ------------- | ----------- |
| Name | String | false | default | The environment in which CluedIn will run. 
| TagOverride | String[] | true | @() | The CluedIn version tag to use for specific services.<br />The names or services match those reported by docker when starting CluedIn<br />e.g. `-tagoverride server=3.2.4-beta,sqlserver=3.2.4-beta` 

## Remove

```
env [[-Name] <string>] -Remove 
```

Removes an environment completely.    

| Parameter | Type | Required | Default Value | Description |
| --------- | ---- | -------- | ------------- | ----------- |
| Name | String | false | default | The environment in which CluedIn will run. 
| Remove | Flag | true | False | When set, fully removes the environment from disk. 

## Unset

```
env [[-Name] <string>] -Unset <string[]> 
```

Removes the current setting for a variable.    

| Parameter | Type | Required | Default Value | Description |
| --------- | ---- | -------- | ------------- | ----------- |
| Name | String | false | default | The environment in which CluedIn will run. 
| Unset | String[] | true |  | The names of variables to be unset in the environment. 

## Tag

```
env [[-Name] <string>] -Tag <string> [-TagOverride <string[]>] 
```

Set the default tag to be used for all CluedIn services.    

| Parameter | Type | Required | Default Value | Description |
| --------- | ---- | -------- | ------------- | ----------- |
| Name | String | false | default | The environment in which CluedIn will run. 
| Tag | String | true | [string]::Empty | The CluedIn version tag to use for all services. 
| TagOverride | String[] | true | @() | The CluedIn version tag to use for specific services.<br />The names or services match those reported by docker when starting CluedIn<br />e.g. `-tagoverride server=3.2.4-beta,sqlserver=3.2.4-beta` 

## Set

```
env [[-Name] <string>] -Set <string[]> [-Tag <string>] [-TagOverride <string[]>] 
```

Set one or more variables within an environment.    

| Parameter | Type | Required | Default Value | Description |
| --------- | ---- | -------- | ------------- | ----------- |
| Name | String | false | default | The environment in which CluedIn will run. 
| Set | String[] | true |  | Variables to set within the environment.<br />e.g. `-set CLUEDIN_SERVER_LOCALPORT=9988,CLUEDIN_SQLSERVER_LOCALPORT=9533` 
| Tag | String | true | [string]::Empty | The CluedIn version tag to use for all services. 
| TagOverride | String[] | true | @() | The CluedIn version tag to use for specific services.<br />The names or services match those reported by docker when starting CluedIn<br />e.g. `-tagoverride server=3.2.4-beta,sqlserver=3.2.4-beta` 


