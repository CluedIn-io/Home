---
title: packages
parent: v3.7.4
---

# packages

Manage packages for a CluedIn instance.
{: .fs-6 .fw-300 }

The packages command controls the configuration and management of
nuget packages to extend and enhance a CluedIn implementation.
Packages can be added from public or private feeds and restored
before starting an environment.

Any changes to the package or feeds list, will require a `clean` and
`restore` to ensure the correct packages are available to the environment.

## List

```
packages [[-Env] <string>] [-List] 
```

Displays the packages and versions that would be restored.    

| Parameter | Type | Required | Default Value | Description |
| --------- | ---- | -------- | ------------- | ----------- |
| Env | String | false | default | The environment in which CluedIn will run. 
| List | Flag | false | False | When set, will display the currently configured package details. 

## Add

```
packages [[-Env] <string>] -Add <string> [-Version <string>] 
```

Adds a package to the package list.    

| Parameter | Type | Required | Default Value | Description |
| --------- | ---- | -------- | ------------- | ----------- |
| Env | String | false | default | The environment in which CluedIn will run. 
| Add | String | true |  | The name of a package to be added to the environment. 
| Version | String | false | [string]::empty | The version of the package to be added.<br />If not provided, the latest release version will be used.<br />May be configured with '<version>-*'. This will cause the latest pre-release<br />of <version> to be restored, or <version> will be restored if it has been released. 

## Remove

```
packages [[-Env] <string>] -Remove <string> 
```

Removes a package from the package list.    

| Parameter | Type | Required | Default Value | Description |
| --------- | ---- | -------- | ------------- | ----------- |
| Env | String | false | default | The environment in which CluedIn will run. 
| Remove | String | true |  | The name of a package to remove from the environment. 

## Add Feed

```
packages [[-Env] <string>] -AddFeed <string> -Uri <string> [-User <string>] [-Pass <string>] [-Tag <string>] [-Pull] 
```

Adds a new package feed to the packages sources.
The feed can be a public url or a local file path.    

| Parameter | Type | Required | Default Value | Description |
| --------- | ---- | -------- | ------------- | ----------- |
| Env | String | false | default | The environment in which CluedIn will run. 
| AddFeed | String | true |  | The name of a feed to be added to the feeds list. 
| Uri | String | true |  | The uri of the feed to be added. 
| User | String | false |  | The username for a feed if the feed requires authentication. 
| Pass | String | false |  | The password for a feed if the feed requires authentication. 
| Tag | String | false | [string]::Empty | When set, will use a specific version of the nuget-installer image. 
| Pull | Flag | false | False | When set, will force a docker pull of the nuget-installer image. 

## Remove Feed

```
packages [[-Env] <string>] -RemoveFeed <string> [-Tag <string>] [-Pull] 
```

Removes a feed from the package sources.    

| Parameter | Type | Required | Default Value | Description |
| --------- | ---- | -------- | ------------- | ----------- |
| Env | String | false | default | The environment in which CluedIn will run. 
| RemoveFeed | String | true |  | The name of a feed to be removed from the feeds list. 
| Tag | String | false | [string]::Empty | When set, will use a specific version of the nuget-installer image. 
| Pull | Flag | false | False | When set, will force a docker pull of the nuget-installer image. 

## Clean

```
packages [[-Env] <string>] -Clean 
```

Removes all restored packages from disk.
Configured package versions and feeds are not removed.    

| Parameter | Type | Required | Default Value | Description |
| --------- | ---- | -------- | ------------- | ----------- |
| Env | String | false | default | The environment in which CluedIn will run. 
| Clean | Flag | true | False | When set, will remove all restored packages for the environment. 

## Restore

```
packages [[-Env] <string>] -Restore [-ClearCache] [-Tag <string>] [-Pull] 
```

Using the configured package sources and package versions,
downloads and collates package libraries to disk so that
the CluedIn environment can install them during startup.    

| Parameter | Type | Required | Default Value | Description |
| --------- | ---- | -------- | ------------- | ----------- |
| Env | String | false | default | The environment in which CluedIn will run. 
| Restore | Flag | true | False | When set, will restore packages for the environment. 
| ClearCache | Flag | false | False | When set, will clear caches. Should be used when restoring local packages<br />where the build number has not changed. 
| Tag | String | false | [string]::Empty | When set, will use a specific version of the nuget-installer image. 
| Pull | Flag | false | False | When set, will force a docker pull of the nuget-installer image. 


