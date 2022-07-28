using namespace System.IO

function DockerCompose {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [String]$Action,
        [String]$Env = 'default',
        [String]$AdditionalArgs = [string]::Empty,
        [String]$Tag = [string]::Empty,
        [String[]]$TagOverride = @(),
        [String[]]$Disable = @(),
        [Switch]$DisableData
    )

    $environment = $Env | FindEnvironment
    if(-not $environment) {
        Write-Host "Could not find environment ${Env}"
        return
    }


    $envPath = $environment.FullName
    $composeRoot = [IO.Path]::Combine($PSScriptRoot, '..', 'docker', 'compose')

    $projectName = "-p cluedin_$($environment.UniqueName)"
    $exclude = @()

    # Exclude installer if start/up
    if($action -eq 'up' -or $action -eq 'start') {
        $exclude += @('docker-compose.installer.yml')
    }

    # Only include libpostal if scale is set
    $libPostalReplicas = [int](GetEnvironmentValue $Env CLUEDIN_LIBPOSTAL_REPLICAS 0)
    if($libPostalReplicas -lt 1){
        $exclude += '*libpostal*'
    }

    # Exclude data if disabled
    if($DisableData) {
        $exclude += '*.data.yml'
    }

    # Note: folder must have '*' to enable filter and exclude to work together
    $composeFiles = Get-ChildItem (Join-Path $composeRoot *) -Filter 'docker-compose*.yml' -Exclude $exclude | ForEach-Object { "-f '$($_.FullName)'" }

    # Support extra docker-compose.yml inside environment folder:
    $composeFiles += Get-ChildItem (Join-Path $envPath *) -Filter 'docker-compose*.yml' | ForEach-Object { "-f '$($_.FullName)'" }

    # If action is up/start - we need to make sure the data folders exist
    try {
        $defaultEnv = FindEnvironment 'default' | Select-Object -ExpandProperty FullName
        Push-Location $envPath
        if($action -eq 'up' -or $action -eq 'start'){
            Get-ChildItem (Join-Path $composeRoot *) -Filter 'docker-compose*.yml' -Exclude $exclude |
                ForEach-Object {
                    Get-Content $_ | ForEach-Object {
                        if($_ -match "^\s+source\:\s+(?<path>.+)$"){
                            if(!(Test-Path $matches['path'])){
                                $source = [IO.Path]::Combine($defaultEnv, $matches['path'])
                                if(Test-Path $source){
                                    $directory = [IO.Path]::GetDirectoryName($matches['path'])
                                    $dir = New-Item $directory -ItemType Directory -Force
                                    if($IsLinux) { chown -R 1000 $dir.FullName }
                                    Copy-Item $source -destination $matches['path']
                                }
                                else {
                                    $dir = New-Item ($matches['path']) -ItemType Directory -Force
                                    if($IsLinux) { chown -R 1000 $dir.FullName }
                                }
                            }
                        }
                    }
                }


            # Prior to 3.3.0 databases for sql were in a different structure - the following caters to
            # move those databases before starting
            # data master translog
            $sqlDataRoot = Join-Path $envPath 'data' 'sqlserver'
            $sqlDataDir = Join-Path $sqlDataRoot 'data'
            if(Test-Path $sqlDataDir) {
                Get-ChildItem $sqlDataDir -Exclude 'datastore.*','.initialized' | Foreach-Object { Move-Item $_ -Destination (Join-Path $sqlDataRoot 'master' $_.Name ) }
                Get-ChildItem $sqlDataDir -Filter '*.ldf' -File | Foreach-Object { Move-Item $_ -Destination (Join-Path $sqlDataRoot 'translog' $_.Name ) }
            }
        }
    } finally {
        Pop-Location
    }

    if($action -eq 'up' -or $action -eq 'start'){
        # If action is up/start - we need to ensure prometheus ports are updated
        $prometheusPath = Join-Path $envPath 'prometheus' 'prometheus.yml'
        # This assumes that the targets are at the end of the file - powershell does not have a yaml converter out of the box
        $prometheusContent = Get-Content $prometheusPath | Where-Object { $_ -notmatch '\s*-\s*host.docker.internal:9' }
        $prometheusContent += @(
            "    - host.docker.internal:$(GetEnvironmentValue $Env CLUEDIN_ANNOTATION_LOCALPORT 9010)"
            "    - host.docker.internal:$(GetEnvironmentValue $Env CLUEDIN_SERVER_PROMETHEUS_METRICS_LOCALPORT 9013)"
            "    - host.docker.internal:$(GetEnvironmentValue $Env CLUEDIN_DATASOURCE_PROMETHEUS_ENDPOINT_METRICS_LOCALPORT 9013)"
            "    - host.docker.internal:$(GetEnvironmentValue $Env CLUEDIN_DATASOURCE_PROMETHEUS_FILE_METRICS_LOCALPORT 9014)"
            "    - host.docker.internal:$(GetEnvironmentValue $Env CLUEDIN_DATASOURCE_PROMETHEUS_SQL_METRICS_LOCALPORT 9015)"
        )
        Set-Content $prometheusPath -Value $prometheusContent
    }

    $compose = "docker-compose $projectName $composeFiles --project-directory '$envPath' --env-file '$(Join-Path $envPath .env)' $action"

    $disableFlags = $Disable | Where-Object { $_ } | ForEach-Object { "--scale ${_}=0" }
    if($disableFlags) { $compose += " ${disableFlags}" }

    if($AdditionalArgs) { $compose += " ${AdditionalArgs}" }

    Write-Verbose "[docker]: $compose"
    $envVars = @{}
    if($Tag){
        $envTags = GetEnvironmentServiceTags -Name $Env
        $envTags.GetEnumerator() | ForEach-Object {
            $envVars[$_.Key] = $Tag
        }
    }

    $TagOverride | ForEach-Object {
        $key,$value = $_ -split '='
        if($key -and $value) {
            $envVars["CLUEDIN_${key}_TAG"] = $value
        }
    }

    $envContext = Set-Environment $envVars
    try {
        Invoke-Expression $compose
    }
    finally {
        $envContext.Reset()
    }
}

function Invoke-DockerComposePull {
    <#
        .SYNOPSIS
        Pulls the latest container images from the container registry.

        .DESCRIPTION
        Docker images may be refreshed using the same tag. Run this command
        to ensure you always have the most up-to-date version image for
        the specified tag.
    #>
    [CmdletBinding()]
    [CluedInAction(Action = 'pull', Header = 'Environment => {0}')]
    param(
        # The environment in which CluedIn will run.
        [Parameter(Position=0)]
        [String]$Env = 'default',
        # The CluedIn version tag to use for all services.
        # Defaults to the setting in the environment.
        [String]$Tag,
        # The CluedIn version tag to use for specific services.
        # The names or services match those reported by docker when starting CluedIn
        # e.g. `-tagoverride server=3.2.4-beta,sqlserver=3.2.4-beta`
        # Defaults to the settings in the environment.
        [String[]]$TagOverride = @()
    )

    <# This is just a proxy function so DockerCompose does not leak internal parameters #>
    DockerCompose pull @PSBoundParameters
}


function Invoke-DockerComposeDown {
    <#
        .SYNOPSIS
        Terminates a running instance of CluedIn.

        .DESCRIPTION
        Running `down` will stop all containers and persisted data.
        The images themselves will not be removed, so this command
        can be used to effectively clear out an instance, ready to
        run again from a clean state.
    #>
    [CmdletBinding()]
    [CluedInAction(Action = 'down', Header = 'Environment => {0}')]
    param(
        # The environment in which CluedIn will run.
        [Parameter(Position=0)]
        [String]$Env = 'default',
        # If set, data for services will be retained for future use.
        [Switch]$KeepData = $false
    )

    # Remove non-shared parameters
    $PSBoundParameters.Remove('KeepData') > $null

    <# This is just a proxy function so DockerCompose does not leak internal parameters #>
    DockerCompose down @PSBoundParameters

    if(-not $KeepData) {
        Invoke-Data -env $env -CleanAll
    }
}


function Invoke-DockerComposeStart {
    <#
        .SYNOPSIS
        Starts a previously stopped instance of CluedIn.

        .DESCRIPTION
        Calling start will restart an instance of CluedIn
        but will not create the containers if they do not exist.
        Use `up` to ensure containers are created.
    #>
    [CmdletBinding()]
    [CluedInAction(Action = 'start', Header = 'Environment => {0}')]
    param(
        # The environment in which CluedIn will run.
        [Parameter(Position=0)]
        [String]$Env = 'default',
        # The CluedIn version tag to use for all services.
        # Defaults to the setting in the environment.
        [String]$Tag,
        # The CluedIn version tag to use for specific services.
        # The names or services match those reported by docker when starting CluedIn
        # e.g. `-tagoverride server=3.2.4-beta,sqlserver=3.2.4-beta`
        # Defaults to the settings in the environment.
        [String[]]$TagOverride = @()
    )

    <# This is just a proxy function so DockerCompose does not leak internal parameters #>
    DockerCompose start @PSBoundParameters
}


function Invoke-DockerComposeStop {
    <#
        .SYNOPSIS
        Stops an instance of CluedIn.

        .DESCRIPTION
        Stopping containers allows them to be started faster in
        the future as the container does not need to be re-created.
    #>
    [CmdletBinding()]
    [CluedInAction(Action = 'stop', Header = 'Environment => {0}')]
    param(
        # The environment in which CluedIn will run.
        [Parameter(Position=0)]
        [String]$Env = 'default'
    )

    <# This is just a proxy function so DockerCompose does not leak internal parameters #>
    DockerCompose stop @PSBoundParameters
}

function Invoke-DockerComposeUp {
    <#
        .SYNOPSIS
        Creates and starts an instance of CluedIn.

        .DESCRIPTION
        If the containers for CluedIn do not exist, they will
        be created and started.  If they do exist, they will
        be restarted.
    #>
    [CluedInAction(Action = 'up', Header = 'Environment => {0}')]
    [CmdletBinding()]
    param(
        # The environment in which CluedIn will run.
        [Parameter(Position=0)]
        [String]$Env = 'default',
        # The CluedIn version tag to use for all services.
        # Defaults to the setting in the environment.
        [String]$Tag,
        # The CluedIn version tag to use for specific services.
        # The names of services match those reported by docker when starting CluedIn
        # e.g. `-tagoverride server=3.2.4-beta,sqlserver=3.2.4-beta`
        # Defaults to the settings in the environment.
        [String[]]$TagOverride = @(),
        # The services to disable during startup. This allows parts
        # of CluedIn to be hosted in docker, with other services hosted
        # locally or on a different network.
        # The names of services match those reported by docker when starting CluedIn
        # e.g. `-disabler server,sqlserver`
        [String[]]$Disable,
        # When set, the latest versions of images will be pulled first.
        [Switch]$Pull,
        # When set, the data folder will not be used for reading/writing data.
        # All data will be persisted directly to the running docker image.
        [Switch]$DisableData = $false
    )

    # Remove non-shared parameters
    $PSBoundParameters.Remove('Pull') > $null
    $PSBoundParameters.Remove('Disable') > $null
    $PSBoundParameters.Remove('DisableData') > $null

    if($Pull) {
        DockerCompose pull @PSBoundParameters
    }

    DockerCompose -Action up -Disable $Disable -DisableData:$DisableData -AdditionalArgs '--remove-orphans -d' @PSBoundParameters
}