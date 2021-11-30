---
title: v3.2.5
has_toc: False
has_children: True
---

# Release Notes - v3.2.5

## Features
- Integration of prometheus and grafana into docker-compose
- Provisioned streams dashboard in Grafana
- Set Prometheus to scrape metrics from port 9013
- Scale Prometheus by setting env variable `CLUEDIN_PROMETHEUS_SCALE_COUNT` to 1 or 0. (0 disables prometheus)
- Add unique suffix to docker compose project name to avoid containers matching wrong environments
- Extend `cluedin status` command with docker container status
- Add stream monitoring
- Expose new `CLUEDIN_SUBMITTER_CLUE_API_URL` to allow changing the endpoint for clue submissions. Defaults to `/api/v1/clue`
- Add web api environment variable to datasource to support calling cluedin server
- Feature flag for De-duplication Projects is now enabled by default. This can be disabled by setting CLUEDIN_UI_FEATURES_DEDUPLICATIONPROJECTS= in your .env file
- Add datasource dashboard to grafana
- Add web api environment variable to clean to support calling cluedin server
- Support for docker compose v2
- Added `CLUEDIN_UI_UPLOAD_LIMIT` to control file upload size. Default is: `1gb`
- Update RabbitMq to 3.9.7

## Fixes
- Ensure prometheus and grafana configs initialise on "up" command
- Move Grafana to port 3030
- Override CluedIn application containers run as `root` user (normally run as non-root `1000` for security) - allows Visual Studio debugging
- UI environment variable `REACT_APP_UI_APP` now includes the host port
- When runnining in Linux, user 1000 is made owner of the `data` folder to enable read/write for docker containers.
- Improve datasource monitoring charts

## Update

### Docker name change

Starting from version 3.2.5 CluedIn inserts a hash into environment name (see more info [here](https://cluedin-io.github.io/Home/faq/env-name)). This means that old docker containers are no longer recognized by `cluedin.ps1` commands. Therefore, it's recommended to `down` the existing environments and `up` them again when updating to latest `Home` version.

To remove the previous environment containers:
- Open your PowerShell session and run `$env:CLUEDIN_LEGACY_ENV_NAME = '1'` to set an environment variable
- Run `cluedin.ps1 down <env>` for the environments you have to clean up.
    To clean all environments: `Get-ChildItem .\env | ForEach-Object { ./cluedin.ps1 down -Env $_.Name }`
- Re-open a new PowerShell session or run `$env:CLUEDIN_LEGACY_ENV_NAME = ''`
- Use `cluedin.ps1 up <env>` to spin up environments as usual


Notice
{: .label .label-blue .mb-0 }

The `CLUEDIN_LEGACY_ENV_NAME` environment variable is supported temporarily for upgrades only. You should not use this environment variable after cleaning containers as it will not be supported in future releases.

