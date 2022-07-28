using namespace System.Management.Automation
using namespace System.Collections.ObjectModel

function Invoke-Environment {
    <#
        .SYNOPSIS
        Management of CluedIn environments.

        .DESCRIPTION
        Environments allow alternative configurations of CluedIn to be managed
        at the same time.

        Using environments, you can configure different versions of CluedIn,
        configure different packages, validate different imports of data, and more.

        .EXAMPLE
        Set

        Set one or more variables within an environment.

        .EXAMPLE
        Tag

        Set the default tag to be used for all CluedIn services.
        .EXAMPLE
        Get

        Displays current variables for an environment.

        .EXAMPLE
        Unset

        Removes the current setting for a variable.

        .EXAMPLE
        Remove

        Removes an environment completely.

        .EXAMPLE
        Tag Override

        Enables overriding specific services with their own version of CluedIn.

    #>
    [CmdletBinding(DefaultParameterSetName='Get')]
    [CluedInAction(Action = 'env', Header = 'Manage Environment')]
    param(
        # The environment in which CluedIn will run.
        [Parameter(Position=0, ParameterSetName='Set')]
        [Parameter(Position=0, ParameterSetName='Tag')]
        [Parameter(Position=0, ParameterSetName='Get')]
        [Parameter(Position=0, ParameterSetName='Unset')]
        [Parameter(Position=0, ParameterSetName='Remove')]
        [Parameter(Position=0, ParameterSetName='Tag Override')]
        [string]$Name = 'default',
        # Variables to set within the environment.
        # e.g. `-set CLUEDIN_SERVER_LOCALPORT=9988,CLUEDIN_SQLSERVER_LOCALPORT=9533`
        [Parameter(ParameterSetName='Set', Mandatory)]
        [string[]]$Set,
        # The CluedIn version tag to use for all services.
        [Parameter(ParameterSetName='Set')]
        [Parameter(ParameterSetName='Tag', Mandatory)]
        [string]$Tag = [string]::Empty,
        # The CluedIn version tag to use for specific services.
        # The names or services match those reported by docker when starting CluedIn
        # e.g. `-tagoverride server=3.2.4-beta,sqlserver=3.2.4-beta`
        [Parameter(ParameterSetName='Set')]
        [Parameter(ParameterSetName='Tag')]
        [Parameter(ParameterSetName='Tag Override', Mandatory)]
        [string[]]$TagOverride = @(),
        # When set, displays information about the environment.
        [Parameter(ParameterSetName='Get')]
        [switch]$Get,
        # The names of variables to be unset in the environment.
        [Parameter(ParameterSetName='Unset',Mandatory)]
        [string[]]$Unset,
        # When set, fully removes the environment from disk.
        [Parameter(ParameterSetName='Remove',Mandatory)]
        [Alias('rm')]
        [switch]$Remove
    )

    process {

        # Base args to match to inner calls
        $innerArgs = @{
            Context = 'docker'
            Name = $Name
        }

        switch ($PSCmdlet.ParameterSetName) {
            {$_ -in @('Set', 'Tag', 'Tag Override')} {
                InvokeEnvironment @innerArgs -Set $Set -SetCustom {

                    ### $env is injected into the scope of this block ###
                    # Update tags
                    if($Tag) {
                        $keys = [string[]]::new($env.Keys.Count)
                        $env.Keys.CopyTo($keys, 0)
                        foreach ($key in $keys) {
                            if($key -match 'CLUEDIN_(\w+)_TAG'){
                                Write-Host "Setting '${key}' in '$Name' environment"
                                $env[$key] = $Tag
                            }
                        }
                    }

                    # Update overrides
                    $TagOverride | ForEach-Object {
                        $key,$value = $_ -split '='
                        if($key -and $value) {
                            $key = $key.ToUpper()
                            Write-Host "Setting 'CLUEDIN_${key}_TAG' in '$Name' environment"
                            $env["CLUEDIN_${key}_TAG"] = $value
                        }
                    }
                }
            }
            'get' {
                InvokeEnvironment @innerArgs
            }
            'unset' {
                InvokeEnvironment @innerArgs -Unset $Unset
            }
            'remove' {
                InvokeEnvironment @innerArgs -Remove
            }
        }
    }
}

function InvokeEnvironment {
    param(
        [Parameter(Position=0, ParameterSetName='set')]
        [Parameter(Position=0, ParameterSetName='get')]
        [Parameter(Position=0, ParameterSetName='unset')]
        [Parameter(Position=0, ParameterSetName='remove')]
        [string]$Name = 'default',
        [Parameter(Position=1, ParameterSetName='set')]
        [Parameter(Position=1, ParameterSetName='get')]
        [Parameter(Position=1, ParameterSetName='unset')]
        [Parameter(Position=1, ParameterSetName='remove')]
        [string]$Context = 'docker',
        [Parameter(ParameterSetName='set')]
        [string[]]$Set,
        [Parameter(ParameterSetName='set')]
        [scriptblock]$SetCustom,
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
                $env = (GetEnvironment $Name $Context) ?? (GetEnvironment 'default' $Context)

                $Set |
                    Where-Object { $_ } |
                    ParseEnvironmentEntry |
                    ForEach-Object {
                        Write-Host "Setting '$($_.Key)' in '$Name' environment"
                        $env[$_.Key] = $_.Value
                    }

                if($SetCustom) {
                    $SetCustom.Invoke($env)
                }

                SetEnvironment $Name $Context $env
            }
            'Get' {
                $env = GetEnvironment $Name $Context
                if(-not $env) {
                    Write-Host "Could not find environment ${Name}";
                    return
                }
                Write-Host "[Environment] ${Name}"
                $env

            }
            'Unset' {
                $env = (GetEnvironment $Name $Context) ?? (GetEnvironment 'default' $Context)
                foreach($rmKey in $Unset){
                    $foundKey = $env.Keys | Where-Object { $_ -eq $rmKey }
                    if($foundKey) {
                        Write-Host "Unsetting '$($foundKey)' in '$Name' environment"
                        $env.Remove($foundKey)
                    }
                }
                SetEnvironment $Name $Context $env
            }
            'Remove' {
                if($Name -eq 'default'){
                    Write-Host "You cannot remove the default environment."
                    return
                }
                $env = FindEnvironment $Name $Context
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
        [string]$Name,
        [string]$Context = 'docker'
    )

    process {
        $root = if($Context -eq 'docker') { [Paths]::Env } else { [Paths]::ClusterEnv }

        $envDir = Get-ChildItem $root -Filter "${Name}" -ErrorAction Ignore

        if(!$envDir) { return $null }

        $envDir | Add-Member -Name UniqueName -MemberType ScriptProperty -Value {
            $dirName = $this.BaseName.ToLowerInvariant()

            # Temporarily simplify update story for customers. Consider removing in 3.3+
            if($env:CLUEDIN_LEGACY_ENV_NAME -eq "1") {
                return $dirName
            }

            $fullPathHash = '{0:x8}' -f [StringHashes]::GetStableHashCode($this.FullName)

            return "$($dirName)_$fullPathHash"
        }

        $envDir
    }
}

function Find-Environment {
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [string]$Context
    )

    FindEnvironment @PSBoundParameters
}

function GetEnvironment {
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [string]$Context = 'docker'
    )

    $env = FindEnvironment $Name $Context
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
        [string]$DefaultValue = '',
        [string]$Context = 'docker'
    )

    $env = FindEnvironment $Name $Context
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
        [string]$Context,
        [Parameter(Mandatory)]
        [hashtable]$Settings
    )

    $root = if($Context -eq 'docker') { [Paths]::Env } else { [Paths]::ClusterEnv }
    $rootPath = Join-Path $root $Name
    if(-not (Test-Path $rootPath)) { New-Item $rootPath -ItemType Directory > $null }
    $content = $Settings.GetEnumerator() |
        ForEach-Object { "$($_.Name.ToUpper())=$($_.Value)" } |
        Sort-Object

    Set-Content (Join-Path $rootPath '.env') -Value $content
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
                Value = if ([string]::IsNullOrEmpty($Matches['value'])) { $null } else { $Matches['value'] }
            }
        } else {
            throw "Invalid environment entry $entry"
        }

        $result
    }
}

function GetEnvironmentServiceTags {
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [string]$Context = 'docker'
    )

    $env = GetEnvironment $Name $Context
    if(!$env) { return }

    $envTags = @{}
    $Env.GetEnumerator() | ForEach-Object {
        if($_.Key -match 'CLUEDIN_(\w+)_TAG'){
            #$envTags[$Matches[1]] = $_.Value
            $envTags[$_.Key] = $_.Value
        }
    }

    $envTags
}