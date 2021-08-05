# Working with Environments

To support different development and testing scenarios, multiple configurations of CluedIn can be configured at one time.

## What is an Environment?

An _environment_ is a folder that contains assets that are required to run an instance of CluedIn.  While running, CluedIn may also persist data to the same folder.  Example assets include:
+ A `.env` file with containing environment variables for CluedIn.
+ A `packages` folder that contains configuration for extensions and restored packages.
+ A `data` folder that contains data being persisted to disk for services.

> All environments are stored under the `env` folder.

## Creating a new Environment
Environments are created by providing a name and a default _tag_ to use for CluedIn services. Running the following will create a new environment called _323_ that uses the `3.2.3` tag for CluedIn services:
```
> .\cluedin.ps1 env 323 -Tag 3.2.3

+------------------------------+
| CluedIn - Manage Environment |
+------------------------------+
Setting 'CLUEDIN_ANNOTATION_TAG' in '323' environment
Setting 'CLUEDIN_CLEAN_TAG' in '323' environment
Setting 'CLUEDIN_DATASOURCE_TAG' in '323' environment
Setting 'CLUEDIN_GQL_TAG' in '323' environment
Setting 'CLUEDIN_INSTALLER_TAG' in '323' environment
Setting 'CLUEDIN_NEO4J_TAG' in '323' environment
Setting 'CLUEDIN_OPENREFINE_TAG' in '323' environment
Setting 'CLUEDIN_SERVER_TAG' in '323' environment
Setting 'CLUEDIN_SQLSERVER_TAG' in '323' environment
Setting 'CLUEDIN_SUBMITTER_TAG' in '323' environment
Setting 'CLUEDIN_UI_TAG' in '323' environment
Setting 'CLUEDIN_WEBAPI_TAG' in '323' environment
```

## How to use Environments
Every command for `cluedin.ps1` (except `version`) accepts an optional `-Env` parameter which can be the name of an _environment_ folder. It can be specified as the argument after the command:

```
> .\cluedin.ps1 up develop
> .\cluedin.ps1 open 324
> .\cluedin.ps1 createorg test -name Example
```

> When running a command, if you do not specify an environment the `default` environment is used. **You should try to work in a custom environment when ever possible!**


