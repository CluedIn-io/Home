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
        [String[]]$Disable = @()
    )

    $envPath = $Env | FindEnvironment | ForEach-Object { "--project-directory '$($_.FullName)'" }
    if(-not $envPath) {
        Write-Host "Could not find environment ${Env}"
        return
    }

    $composeRoot = [IO.Path]::Combine($PSScriptRoot, '..', 'docker', 'compose')

    $projectName = "-p cluedin_$($Env.ToLowerInvariant())"
    $composeFiles = Get-ChildItem $composeRoot -Filter 'docker-compose*.yml' | ForEach-Object { "-f '$($_.FullName)'" }

    $compose = "docker-compose $projectName $composeFiles $envPath $action"

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

function Invoke-DockerCompose {
    [CmdletBinding()]
    [CluedInAction(Action = 'pull', Header = 'Environment => {0}')]
    [CluedInAction(Action = 'down', Header = 'Environment => {0}')]
    [CluedInAction(Action = 'start', Header = 'Environment => {0}')]
    [CluedInAction(Action = 'stop', Header = 'Environment => {0}')]
    param(
        [Parameter(Mandatory)]
        [String]$Action,
        [String]$Env = 'default',
        [String]$Tag,
        [String[]]$TagOverride = @()
    )

    <# This is jsut a proxy function so DockerCompose does not leak intenal parameters #>
    DockerCompose @PSBoundParameters
}


function Invoke-DockerComposeUp {
    [CluedInAction(Action = 'up', Header = 'Environment => {0}')]
    [CmdletBinding()]
    param(
        [String]$Env = 'default',
        [String]$Tag,
        [String[]]$TagOverride = @(),
        [String[]]$Disable,
        [Switch]$Pull
    )

    # Remove non-shared parameters
    $PSBoundParameters.Remove('Pull') > $null
    $PSBoundParameters.Remove('Disable') > $null

    if($Pull) {
        DockerCompose -Action 'pull' @PSBoundParameters
    }

    DockerCompose -Action 'up' -Disable $Disable -AdditionalArgs '--remove-orphans -d' @PSBoundParameters
}