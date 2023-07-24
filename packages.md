# Working with Packages

Extension packages can be restored for an environment to extend CluedIn
with additional features (e.g. crawlers, export targets, and vocabularies).

Packages are made available through [nuget] feeds that can be publicly or privately hosted, or even directly hosted from your local machine.

> Check the full package documentation for all commands and options.

## Local Package Development

To support local development an environment is pre-configured with a `packages/local` nuget folder.
This is a folder that allows developers to place locally built nuget packages to be included in a CluedIn environment.

The easiest way to integrate your locally built packages into CluedIn, is to build your extension packages directly to this folder.

### Common Development Loop

### 1. Prepare the environment
To begin setup an environment for local development that targets CluedIn 3.2.3 (use whichever version is relevant to you).  We'll call it `custom`:
```powershell
> .\cluedin.ps1 env custom -Tag 3.2.3

+------------------------------+
| CluedIn - Manage Environment |
+------------------------------+
Setting 'CLUEDIN_ANNOTATION_TAG' in 'custom' environment
Setting 'CLUEDIN_CLEAN_TAG' in 'custom' environment
Setting 'CLUEDIN_DATASOURCE_TAG' in 'custom' environment
Setting 'CLUEDIN_GQL_TAG' in 'custom' environment
Setting 'CLUEDIN_INSTALLER_TAG' in 'custom' environment
Setting 'CLUEDIN_NEO4J_TAG' in 'custom' environment
Setting 'CLUEDIN_OPENREFINE_TAG' in 'custom' environment
Setting 'CLUEDIN_SERVER_TAG' in 'custom' environment
Setting 'CLUEDIN_SQLSERVER_TAG' in 'custom' environment
Setting 'CLUEDIN_SUBMITTER_TAG' in 'custom' environment
Setting 'CLUEDIN_UI_TAG' in 'custom' environment
```

### 2. Add a reference to your package
In this example, we are building a package called `MyCustomExtension`. To ensure it is restored as part of CluedIn, we need to add it to the package list for the environment:

```powershell
> .\cluedin.ps1 packages custom -Add MyCustomExtension

+--------------------+
| CluedIn - Packages |
+--------------------+
Added package MyCustomExtension
```

> You can also specify a version for your package if you need to using `-version`.
> You can also use [floating versions] e.g. `1.0.0-*` for the latest pre-release.

### 3. Pack your extension

We can now build our extension as a nuget package - providing the path to the custom environment `local` folder:
```cmd
> dotnet pack .\MyCustomExtension\ -o .\env\custom\packages\local\

Microsoft (R) Build Engine version 16.9.0+57a23d249 for .NET
Copyright (C) Microsoft Corporation. All rights reserved.

  Determining projects to restore...
  All projects are up-to-date for restore.
  MyCustomExtension -> ..\src\MyCustomExtension\bin\Debug\netcoreapp3.1\MyCustomExtension.dll
  Successfully created package '..\env\custom\packages\local\MyCustomExtension.1.0.0.nupkg'.
```

#### Always build and pack
You can also configure your extension project to always build and pack to the local folder by modifying the `MyCustomExtension.csproj`
```xml
<PropertyGroup>
  <GeneratePackageOnBuild>true</GeneratePackageOnBuild>
  <PackageOutputPath>..\env\custom\packages\local\</PackageOutputPath>
</PropertyGroup>
```

```cmd
> dotnet build .\MyCustomExtension\

Microsoft (R) Build Engine version 16.9.0+57a23d249 for .NET
Copyright (C) Microsoft Corporation. All rights reserved.

  Determining projects to restore...
  All projects are up-to-date for restore.
  MyCustomExtension -> ..\MyCustomExtension\bin\Debug\netcoreapp3.1\MyCustomExtension.dll
  Successfully created package '..\env\custom\packages\local\MyCustomExtension.1.0.0.nupkg'.
```

### 4. Restore packages for CluedIn
Now we have the package available and configured for CluedIn, we need to restore our packages for CluedIn to consume
```powershell
> .\cluedin.ps1 packages custom -Restore

+--------------------+
| CluedIn - Packages |
+--------------------+
# ...
ServerComponent.Extensions -> /tmp/ServerComponent.Extensions/ServerComponent.Extensions.dll
  [Package Trimming]: Removing 0 libraries from publish output that are available in the runtime store
  [Package Trimming]: Removing 0 asset(s) from publish output that are available in the host
  ServerComponent.Extensions -> /components/ServerComponent/
```

### 5. Now start CluedIn
Finally we can start our CluedIn instance:
```powershell
> .\cluedin.ps1 up custom

+-----------------------------+
| CluedIn - Environment => up |
+-----------------------------+
Creating network "cluedin_custom_default" with the default driver
Creating cluedin_custom_elasticsearch_1 ...
Creating cluedin_custom_neo4j_1         ...
Creating cluedin_custom_sqlserver_1     ... done
Creating cluedin_custom_redis_1         ... done
Creating cluedin_custom_openrefine_1    ... done
Creating cluedin_custom_seq_1           ... done
# ...
```

### 6. Confirm your package was included
To confirm our custom package was included, we can check the docker logs for the libraries and dependencies that were restored.

When CluedIn starts up, it's first task is to take the all the extension assets from disk and to copy them into the container.

```powershell
> docker logs cluedin_custom_server_1

Register CA Certificate - [SKIPPED - No File]
Enable COREDUMP mode - [SKIPPED]
'../components/ServerComponent/MyCustomExtension.dll' -> './ServerComponent/MyCustomExtension.dll'
'../components/ServerComponent/ServerComponent.Extensions.deps.json' -> './ServerComponent/ServerComponent.Extensions.deps.json'
'../components/ServerComponent' -> './ServerComponent'

Installing component extensions - [COMPLETE]
```

### 7. Restart Server

As our package contents are copied _into_ the container we must restart the cluedin server. We can do this by calling `up` and excluding the service,
followed by calling `up` again with all services.

```powershell
> .\cluedin.ps1 up custom -disable server
> .\cluedin.ps1 up custom
```
### 8. Update your package

Any changes to the `packages.txt` will require `-restore` to be called again.
If you are using [floating versions] and you want to restore a new version of a package, you can simply run `-restore` again.

> When building packages locally, it is **strongly** recommended to ensure your package builds with a new version each time. NuGet (which underpins the restore process) assumes once a package is available for a specific version, it will not change in future, so it is persisted in a cache for future requests.

If you rebuild the _same version_ you have previously restored, you will need to clear the cache during a restore by passing the `-ClearCache` flag. All nuget packages are stored in the same cache it is not currently possible to clear the cache for a specific feed.
```powershell
> .\cluedin.ps1 packages custom -Restore -Force -ClearCache
> .\cluedin.ps1 up custom -disable server
> .\cluedin.ps1 up custom
```

[nuget]: https://docs.microsoft.com/en-us/nuget/what-is-nuget
[floating versions]: https://docs.microsoft.com/en-us/nuget/concepts/dependency-resolution#floating-versions