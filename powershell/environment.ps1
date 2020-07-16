using namespace System.Management.Automation
using namespace System.Collections.ObjectModel

function Invoke-Environment {
    [CmdletBinding(DefaultParameterSetName='get')]
    [CluedInAction(Action = 'env', Header = 'Manage Environment')]
    param(
        [Parameter(Position=0,ParameterSetName='set')]
        [Parameter(Position=0,ParameterSetName='get')]
        [Parameter(Position=0,ParameterSetName='unset')]
        [Parameter(Position=0,ParameterSetName='remove')]
        [string]$Name = 'default',
        [Parameter(ParameterSetName='set',Mandatory)]
        [string[]]$Set,
        [Parameter(ParameterSetName='get')]
        [switch]$Get,
        [Parameter(ParameterSetName='unset',Mandatory)]
        [string[]]$Unset,
        [Parameter(ParameterSetName='remove',Mandatory)]
        [Alias('rm')]
        [switch]$Remove
    )

    process {

        switch ($PSCmdlet.ParameterSetName) {
            'set' {
                $env = (GetEnvironment $Name) ?? @{}
                $Set |
                    ParseEnvironmentEntry |
                    ForEach-Object {
                        Write-Host "Setting '$($_.Key)' in '$Name' environment"
                        $env[$_.Key] = $_.Value
                    }

                SetEnvironment $Name $env
            }
            'get' {
                $env = GetEnvironment $Name
                if(-not $env) {
                    Write-Host "Could not find environment ${Name}";
                    return
                }
                Write-Host "[Environment] ${Name}"
                $env

            }
            'unset' {
                $env = (GetEnvironment $Name) ?? @{}
                foreach($rmKey in $Unset){
                    $foundKey = $env.Keys | Where-Object { $_ -eq $rmKey }
                    if($foundKey) {
                        Write-Host "Unsetting '$($_.Key)' in '$Name' environment"
                        $env.Remove($foundKey)
                    }
                }
                SetEnvironment $Name $env
            }
            'remove' {
                $env = FindEnvironment $Name
                if($env) {
                    Write-Host "Removing '$Name' environment"
                    Remove-Item $env
                }
            }
        }
    }
}

function FindEnvironment {
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Name
    )

    process {
        Get-ChildItem ([Paths]::Env) -Filter "${Name}.env" -ErrorAction Ignore
    }
}

function GetEnvironment {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $env = FindEnvironment $Name
    $result = $null

    if($env) {
        $result = [ordered]@{}
        Get-Content $env |
            ParseEnvironmentEntry |
            ForEach-Object { $result[$_.Key] = $_.Value }

    }

    $result
}

function SetEnvironment {
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [hashtable]$Settings
    )

    $Settings.GetEnumerator() |
        ForEach-Object { "$($_.Name)=$($_.Value)" } |
        Sort-Object |
        Set-Content (Join-Path ([Paths]::Env) "${Name}.env")
}

function ParseEnvironmentEntry {
    param(
        [Parameter(ValueFromPipeline, Mandatory)]
        [string]$Entry
    )

    process {
        $result = $null

        if($Entry -match '^(?<key>[^=]+)=(?<value>.*)$'){
            $result = @{
                Key = $Matches['key'].ToUpper()
                Value = $Matches['value']
            }
        } else {
            throw "Invalid environment entry $entry"
        }

        $result
    }
}