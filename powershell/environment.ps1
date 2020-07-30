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
                $env = (GetEnvironment $Name) ?? (GetEnvironment 'default')
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
                $env = (GetEnvironment $Name) ?? (GetEnvironment 'default')
                foreach($rmKey in $Unset){
                    $foundKey = $env.Keys | Where-Object { $_ -eq $rmKey }
                    if($foundKey) {
                        Write-Host "Unsetting '$($foundKey)' in '$Name' environment"
                        $env.Remove($foundKey)
                    }
                }
                SetEnvironment $Name $env
            }
            'remove' {
                if($Name -eq 'default'){
                    Write-Host "You cannot remove the default environment."
                    return
                }
                $env = FindEnvironment $Name
                if($env) {
                    Write-Host "Removing '$Name' environment"
                    Remove-Item $env -Recurse -Force
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
        Get-ChildItem ([Paths]::Env) -Filter "${Name}" -ErrorAction Ignore
    }
}

function GetEnvironment {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $env = FindEnvironment $Name
    if(!$env) { return $null}

    $envPath = Join-Path $env '.env'
    $result = $null

    if(Test-Path $envPath) {
        $result = [ordered]@{}
        Get-Content $envPath |
            ParseEnvironmentEntry |
            ForEach-Object { $result[$_.Key] = $_.Value }
    }

    $result
}

function GetEnvironmentValue {
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [string]$Key,
        [string]$DefaultValue = ''
    )

    $env = FindEnvironment $Name
    $envPath = Join-Path $env '.env'

    if(Test-Path $envPath) {
        $found = Get-Content $envPath |
                    ParseEnvironmentEntry |
                    Where-Object { $_.Key -eq $Key }

        $result = if($found) { $found.Value }

        if(![string]::IsNullOrWhiteSpace($result)) {
            return $result
        } else {
            return $DefaultValue
        }
    }
    Write-Error "Could not find environment ${Env}";
}

function SetEnvironment {
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [hashtable]$Settings
    )

    $rootPath = Join-Path ([Paths]::Env) $Name
    if(-not (Test-Path $rootPath)) { New-Item $rootPath -ItemType Directory > $null }
    $Settings.GetEnumerator() |
        ForEach-Object { "$($_.Name)=$($_.Value)" } |
        Sort-Object |
        Set-Content (Join-Path $rootPath '.env')
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