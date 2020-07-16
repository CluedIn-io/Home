# Welcome To CluedIn on Github

This is the starting point for getting a brand new instance of CluedIn up and running.

Please take the time to read the documentation and look at the prerequisites before jumping in.

## Documentation

You can find all the documentation for CluedIn here : https://documentation.cluedin.net/

# Local Docker Install

## Prerequisites

* 16GB of free memory (it is advisable to run this on a 32GB machine)
* [Docker](https://www.docker.com/products/docker-desktop)
* [Docker-compose](https://docs.docker.com/compose/)
* [PowerShell 7+](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7)
* Access to [CluedIn DockerHub](https://hub.docker.com/orgs/cluedin) repositories (to download CluedIn container images)
* [Git](https://git-scm.com/)

You can also use the `cluedin.ps1` Docker helper script  `check` command to check the system for you. Please see [below](#check) for more information.

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

> You can omit the `pwsh` part of the command if you are running from inside a PowerShell console.

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

### Stop

```bash
pwsh cluedin.ps1 stop
```
Usage: (with specific tag)
```bash
pwsh cluedin.ps1 stop -tag 3.1-alpha
```

This command will stop all the CluedIn containers abut not remove the data. The containers can be brought back online by using the `up` command again.

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
