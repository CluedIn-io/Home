---
nav_order: 1
---

# Home

This is the starting point for getting a brand new instance of CluedIn up and running locally.
{: .fs-6 .fw-300 }

## Prerequisites

- 16GB of free memory (it is advisable to run this on a 32GB machine)
- [Docker](https://www.docker.com/products/docker-desktop)
- [Docker-compose](https://docs.docker.com/compose/) (installed with Docker)
- [PowerShell 7+](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7)
- Access to [CluedIn DockerHub](https://hub.docker.com/orgs/cluedin) repositories (to download CluedIn container images)
- [Git](https://git-scm.com/)

### Execution policy
{: .d-inline-block }

Windows only
{: .label .label-red }

To enable local scripts to run, you will need to modify the PowerShell execution policy. This only needs to be ran once:
```powershell
> Set-ExecutionPolicy RemoteSigned
```

### Run as admin
You should run your terminal session as an administrator, or `sudo` for non-windows environments.

## Quick Start

> All examples are provided as if running in a PowerShell session.
> To begin a PowerShell session, enter the command `pwsh` [and a new session will start](./faq/pwsh.md)

```powershell
# Check out the repository
> git clone https://github.com/CluedIn-io/Home.git

# Move to the checkout directory
> cd Home

# Log in to DockerHub
> docker login

# Create a new environment targeting the latest version
> .\cluedin.ps1 env latest -Tag latest

# Check default ports are available
> .\cluedin.ps1 check latest

# Start CluedIn
> .\cluedin.ps1 up latest

# Create an organization
> .\cluedin.ps1 createorg latest -Name example -Pass Example123!
# this will provide the login details you need e.g
# ...
# Email: admin@example.com
# Password: Example123!


# Open the login page
> .\cluedin.ps1 open latest -Org example

```

> Cluedin uses the address `http://app.127.0.0.1.nip.io:9080` by default.
