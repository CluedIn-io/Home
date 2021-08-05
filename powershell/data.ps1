function Invoke-Data {
    <#
        .SYNOPSIS
        Identifies and clears data for an instance of CluedIn.

        .DESCRIPTION
        When an environment is started, one or more services may store data
        outside of the container so that it can be used for future scenarios.
        This command enables identification and removal of persisted data.

        .EXAMPLE
        Get Details

        Displays information on the persisted data for an environment.
        e.g
        ```
        > .\cluedin.ps1 data
        Name          Size      Items
        ----          ----      -----
        elasticsearch 0.49 MB      56
        neo4j         0.91 MB      43
        sqlserver     240.06 MB    32
        ```

        .EXAMPLE
        Clear Service(s)

        Removes the persisted data for one or more services.

        .EXAMPLE
        Clear All

        Forces all persisted data for all services to be wiped from disk.
    #>
    [CluedInAction(Action = 'data', Header = 'Data')]
    [CmdletBinding(DefaultParameterSetName='Get Details')]
    param(
        # The environment in which CluedIn will run.
        [Parameter(Position=0, ParameterSetName='Get Details')]
        [Parameter(Position=0, ParameterSetName='Clear Service(s)')]
        [Parameter(Position=0, ParameterSetName='Clear All')]
        [string]$Env = 'default',
        # Specify one or more service names who's data is to be cleared.
        [Parameter(Mandatory, ParameterSetName='Clear Service(s)')]
        [string[]]$Clean = $null,
        # Clears all data for all services.
        [Parameter(Mandatory, ParameterSetName='Clear All')]
        [switch]$CleanAll
    )

    $envPath = $Env | FindEnvironment
    if(-not $envPath) {
        Write-Host "Could not find environment ${Env}"
        return
    }

    $dataRoot = Join-Path $envPath 'data'
    if(-not (Test-Path $dataRoot)) {
        Write-Host "No data found for ${Env}"
        return
    }

    function CleanData {
        param(
            [Parameter(Mandatory)]
            [string]$Path,
            [Parameter(Mandatory)]
            [string]$Name
        )

        if(Test-Path $Path) {
            Write-Host "Clearing data for ${Name}"
            Remove-Item $Path -Recurse -Force
        } else {
            Write-Host "No data found for ${Name}"
        }
    }

    if($PSCmdlet.ParameterSetName -eq 'Clear Service(s)') {

        $Clean | ForEach-Object {
            $dataPath = Join-Path $dataRoot $_
            $name = "${Env}:${_}"
            CleanData -Path $dataPath -Name $name
        }
    }

    if($PSCmdlet.ParameterSetName -eq 'Clear All') {
        CleanData -Path $dataRoot -Name $Env
        return
    }

    # Log remaining size
    Get-ChildItem $dataRoot -Directory |
        Foreach-Object {
            $name = $_.Name
            Get-ChildItem $_ -Recurse -Force | Measure-Object Length -Sum | ForEach-Object {
                [PSCustomObject]@{
                    Name = $name
                    Size = "{0:0.00} MB" -f ($_.Sum / 1MB)
                    Items = $_.Count
                }
            }
        }
}