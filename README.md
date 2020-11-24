# Welcome To CluedIn on Github

This is the starting point for getting a brand new instance of CluedIn up and running.

Please take the time to read the documentation and look at the prerequisites before jumping in.

## Documentation

You can find all the documentation for CluedIn here : https://documentation.cluedin.net/

# Local Docker Install

## Prerequisites

- 16GB of free memory (it is advisable to run this on a 32GB machine)
- [Docker](https://www.docker.com/products/docker-desktop)
- [Docker-compose](https://docs.docker.com/compose/) (installed with Docker)
- [PowerShell 7+](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7)
- Access to [CluedIn DockerHub](https://hub.docker.com/orgs/cluedin) repositories (to download CluedIn container images)
- [Git](https://git-scm.com/)

You can also use the `cluedin.ps1` Docker helper script `check` command to check the system for you. Please see [below](#check) for more information.

## Extreme Quick Start

```bash
git clone https://github.com/CluedIn-io/Home.git

cd Home

docker login

pwsh cluedin.ps1 up

open http://app.127.0.0.1.xip.io
```

## Using the Docker helper script

This script has various commands to help save you time configuring and managing the container instances in Docker.

All commands are ran with the following syntax

```bash
# In PowerShell
> .\cluedin.ps1 <command> [options]

# Alternative syntax for non-PowerShell (e.g. bash)
> pwsh cluedin.ps1 <command> [options]
```

> You can omit the `pwsh` part of the command if you are running from inside a PowerShell console.

### Using Environments

You can use this script to configure multiple environments with different configurations for testing and validation.
All commands (except `version`) can receive the name of an environment when invoked.

e.g. To start a specific environment configuration called _local_ use `pwsh cluedin.ps1 up local`

> For details on configuring environments see the [`env` command](#Custom-Environments)

### Updating the Script

> To prevent issues with updating it is **highly** recommended to use [envrionments](#Custom-Environments) so your custom
> configuration is not lost during updates.

> After updating, you may still need to re-configure your custom environments.

To update your local version of the script run:
```bash
> git pull
```

if you see a warning such as:
```
error: Your local changes to the following files would be overwritten by merge:
        src/env/default.env
Please commit your changes or stash them before you merge.
Aborting
```

Make a back up of your files and run:
```
> git clean -fdx
> git pull
```
> You will need to manually or use the [commands](#Commands) to re-apply your customizations


## Commands

| Command Name          | Description                                                       |
| --------------------- | ----------------------------------------------------------------- |
| [`check`](#Check)     | Checks the environment for necessary configuration to run CluedIn |
| [`status`](#Status)   | Validates the status of a running instance of CluedIn             |
| [`up`](#Up)           | Creates or restarts an instance of CluedIn                        |
| [`down`](#Down)       | Stops and destroys an instance of CluedIn                         |
| [`start`](#Start)     | Restarts an instance of CluedIn                                   |
| [`stop`](#Stop)       | Stops an instance of CluedIn                                      |
| [`pull`](#Pull)       | Fetches new versions of CluedIn docker images                     |
| [`env`](#Env)         | Manages environment configurations for instances of CluedIn       |
| [`version`](#Version) | Prints version information for this tool                          |

### Check

Usage:

```bash
pwsh cluedin.ps1 check
```

This command will print a report showing if all needed programs are installed and also if any ports CluedIn needs to run are available.

Please see the [CluedIn documentation](#Documentation) for more information on system requirements.

### Pull

Usage: (default)

```bash
pwsh cluedin.ps1 pull
```

Usage: (with specific tag)

```bash
pwsh cluedin.ps1 pull -tag 3.1-alpha
```

This command will pull any required containers onto your local machine. As it is a download operation the speed of this command to complete is dependant on network speed.

This command is also useful for refreshing a set of images you may have pulled before and need updating.

### Up

Usage: (default)

```bash
pwsh cluedin.ps1 up
```

Usage: (with specific tag)

```bash
pwsh cluedin.ps1 up -tag 3.1-alpha
```

This command will start all the containers needed to run CluedIn and start them.

If they are not already present on your local machine this command will also download them the first time(To update images subsequently see: [Pull](#Pull))

### Down

```bash
pwsh cluedin.ps1 down
```

Usage: (with specific tag)

```bash
pwsh cluedin.ps1 down -tag 3.1-alpha
```

This command will stop all the CluedIn containers and remove the instances and their data from the current system.

It will **not** delete the container images, only the instances and data associated with those running instances.

### Start

```bash
pwsh cluedin.ps1 start
```

Usage: (with specific tag)

```bash
pwsh cluedin.ps1 start -tag 3.1-alpha
```

This command will start all the CluedIn containers but not create new instances.

### Stop

```bash
pwsh cluedin.ps1 stop
```

Usage: (with specific tag)

```bash
pwsh cluedin.ps1 stop -tag 3.1-alpha
```

This command will stop all the CluedIn containers but not remove the data. The containers can be brought back online by using the `start` or `up` command.

### Status

```bash
pwsh cluedin.ps1 status
```

This command will display a list of status checks for various CluedIn sub-systems.

If all checks are green then it is ok to start using CluedIn.

You may have to wait a small amount of time for the SQL Server image to run and instantiate the CluedIn tables so the status command is useful for informing you that this has completed.

### Env

Usage: (list all variables)

```bash
pwsh cluedin.ps1 env
```

This command prints a list of environment flags and settings that the helper script uses when it is starting the system.

Usage: (set a specific value)

```bash
pwsh cluedin.ps1 env -set [NAME]=[VALUE]
```

This sub-command allows the setting of a particular environment variable. This can be useful for setting things like log verbosity or supplying SMTP details for the email functionality.

#### Custom Environments

```bash
pwsh cluedin.ps1 env local -set [NAME]=[VALUE]
```

This sub-command allows the setting of environment variables to a custom environment file, e.g. `local`. You can then pass the custom environment to most other commands to use that environment:

Usage: (`up` with a local environment)

```bash
pwsh cluedin.ps1 up -env local
```

### Version

```bash
pwsh cluedin.ps1 version
```

This sub-command prints the current version information for this script.

## Ports - Internal and External Mappings

| Service Name  | Local Port | Internal Port | Port Name               |
| ------------- | ---------- | ------------- | ----------------------- |
| server        | 9000       | 9000          | Server API              |
|               | 9001       | 9001          | Auth                    |
|               | 9003       | 9003          | Jobs API                |
|               | 9006       | 9006          | Webhooks                |
|               | 9007       | 9007          | Public API              |
| webapi        | 9008       | 9008          | Web API                 |
| clean         | 9009       | 8888          | Clean API               |
| annotation    | 9010       | 8888          | Annotation API          |
| datasource    | 9011       | 8888          | DataSource API          |
| submitter     | 9012       | 8888          | Submitter API           |
| gql           | 8888       | 8888          | GraphQL                 |
| ui            | 9080       | 80            | UI/System Entrypoint    |
| neo4j         | 7474       | 7474          | Neo4J Data              |
|               | 7687       | 7687          | Neo4J Bolt              |
| elasticsearch | 9200       | 9200          | ElasticSearch Data      |
|               | 9300       | 9300          | ElasticSearch HTTP/REST |
| rabbitmq      | 5672       | 5672          | RabbitMQ Data           |
|               | 15672      | 15672         | RabbitMQ HTTP           |
| redis         | 6379       | 6379          | Redis Data              |
| seq           | 3200       | 80            | Seq UI                  |
|               | 5341       | 5341          | Seq Data                |
| sqlserver     | 1433       | 1433          | SQL Server Data         |
| openrefine    | 3333       | 3333          | OpenRefine API          |
