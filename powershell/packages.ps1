$script:initConfig = @"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <add key="local" value="/packages/local" />
  </packageSources>
</configuration>
"@

function Invoke-Packages {
    <#
        .SYNOPSIS
        Manage packages for a CluedIn instance.
        
        .DESCRIPTION
        The packages command controls the configuration and management of
        nuget packages to extend and enhance a CluedIn implementation.
        Packages can be added from public or private feeds and restored
        before starting an environment.

        Any changes to the package or feeds list, will require a `clean` and
        `restore` to ensure the correct packages are available to the environment.

        .EXAMPLE
        List

        Displays the packages and versions that would be restored.

        .EXAMPLE
        Add

        Adds a package to the package list.

        .EXAMPLE
        Remove

        Removes a package from the package list.

        .EXAMPLE
        Add Feed

        Adds a new package feed to the packages sources.
        The feed can be a public url or a local file path.

        .EXAMPLE
        Remove Feed

        Removes a feed from the package sources.

        .EXAMPLE
        Clean

        Removes all restored packages from disk.
        Configured package versions and feeds are not removed.

        .EXAMPLE
        Restore

        Using the configured package sources and package versions,
        downloads and collates package libraries to disk so that
        the CluedIn environment can install them during startup.
    #>
    [CluedInAction(Action = 'packages', Header = 'Packages')]
    [CmdletBinding(DefaultParameterSetName='List')]
    param(
        # The environment in which CluedIn will run.
        [Parameter(Position=0)]
        [string]$Env = 'default',
        # When set, will display the currently configured package details.
        [Parameter(ParameterSetName='List')]
        [switch]$List = $false,
        # The name of a package to be added to the environment.
        [Parameter(ParameterSetName='Add', Mandatory)]
        [string]$Add,
        # The version of the package to be added.
        # If not provided, the latest release version will be used.
        # May be configured with '<version>-*'. This will cause the latest pre-release
        # of <version> to be restored, or <version> will be restored if it has been released.
        [Parameter(ParameterSetName='Add')]
        [string]$Version = [string]::empty,
        # The name of a package to remove from the environment.
        [Parameter(ParameterSetName='Remove', Mandatory)]
        [string]$Remove,
        # The name of a feed to be added to the feeds list.
        [Parameter(ParameterSetName='Add Feed', Mandatory)]
        [string]$AddFeed,
        # The uri of the feed to be added.
        [Parameter(ParameterSetName='Add Feed', Mandatory)]
        [string]$Uri,
        # The username for a feed if the feed requires authentication.
        [Parameter(ParameterSetName='Add Feed')]
        [string]$User,
        # The password for a feed if the feed requires authentication.
        [Parameter(ParameterSetName='Add Feed')]
        [string]$Pass,
        # The name of a feed to be removed from the feeds list.
        [Parameter(ParameterSetName='Remove Feed', Mandatory)]
        [string]$RemoveFeed,
        #  When set, will remove all restored packages for the environment.
        [Parameter(ParameterSetName='Clean', Mandatory)]
        [switch]$Clean,
        # When set, will restore all packages for the environment.
        [Parameter(ParameterSetName='Restore', Mandatory)]
        [switch]$Restore,
        # When set, will use a specific version of the nuget-installer image.
        [Parameter(ParameterSetName='Restore')]
        [Parameter(ParameterSetName='Add Feed')]
        [Parameter(ParameterSetName='Remove Feed')]
        [String]$Tag = [string]::Empty,
        # When set, will force a docker pull of the nuget-installer image.
        [Parameter(ParameterSetName='Restore')]
        [Parameter(ParameterSetName='Add Feed')]
        [Parameter(ParameterSetName='Remove Feed')]
        [switch]$Pull
    )

    $envPath = $Env | FindEnvironment
    if(-not $envPath) {
        Write-Host "Could not find environment ${Env}"
        return
    }

    if(!$Tag){
        $Tag = GetEnvironmentValue $Env 'CLUEDIN_INSTALLER_TAG'
    }

    $image = "cluedin/nuget-installer:$tag"
    if($Pull) {
        $pullCommand = "docker pull $image"
        Write-Verbose "[docker]: $pullCommand"
        Invoke-Expression $pullCommand
    }

    $components = Join-Path $envPath 'components'
    $packages = Join-Path $envPath 'packages'
    $packagesLocal = Join-Path $packages 'local'
    $packagesConfig = Join-Path $packages 'nuget.config'
    $packagesTxt = Join-Path $packages 'packages.txt'

    $baseDotnetCommand = "docker run --rm -a stdout -a stderr -v '${packages}:/packages' --entrypoint dotnet $image"

    # Configure base assets if they do not exist
    New-Item $packages -ItemType Directory -Force > $null
    if(!(Test-Path $packagesConfig)){
        Set-Content $packagesConfig -Value $script:initConfig
    }

    if(!(Test-Path $packagesLocal)){
        New-Item $packagesLocal -ItemType Directory > $null
    }

    if(!(Test-Path $packagesTxt)){
        New-Item $packagesTxt -ItemType File > $null
    }

    function ReadPackageList {
        $packageList = Get-Content $packagesTxt -ErrorAction Ignore |
            ForEach-Object {
                $p,$v = $_ -split ' '
                [PSCustomObject]@{
                    Package = $p
                    Version = $v
                }
            } |
            Where-Object { $_.Package } |
            Sort-Object 'Package'

        return $packageList
    }

    function WritePackageList {
        param(
            [PSCustomObject[]]$Entries
        )

        Remove-Item $packagesTxt -ErrorAction Ignore
        New-Item $packagesTxt -ItemType File > $null
        $Entries |
            Sort-Object 'Name' |
            ForEach-Object {
                Add-Content $packagesTxt -Value (($_.Package,$_.Version) -join ' ')
            }
    }

    switch ($PSCmdlet.ParameterSetName) {
        'Add' {
            $packageList = [array](ReadPackageList)
            $updated = $false
            foreach($entry in $packageList)
            {
                if($entry.Package -eq $Add){
                    $entry.Version = $Version
                    $updated = $true;
                    break;
                }
            }

            if(!$updated) {
                $packageList += [PSCustomObject]@{
                    Package = $Add
                    Version = $Version
                }
            }

            Write-Host "Added package ${Add}" -NoNewline
            if(![string]::IsNullOrWhiteSpace($Version)) {
                Write-Host " - ${Version}"
            } else {
                Write-Host
            }
            WritePackageList $packageList
        }
        'Remove' {
            $packageList = [array](ReadPackageList)
            $newList = $packageList | Where-Object { $_.Package -ne $Remove }

            Write-Host "Remove package ${Remove}"
            WritePackageList $newList
        }
        'List' {
            $packageList = [array](ReadPackageList)

            if($packageList.Count) {
                $packageList
            } else {
                Write-Host 'No packages specified'
            }
        }
        'Add Feed' {
            $nugetCmd = " nuget add source $Uri -n $AddFeed"

            if($User) { $nugetCmd += " -u $User" }
            if($Pass) { $nugetCmd += " -p $Pass --store-password-in-clear-text" }

            $nugetCmd += " --configfile /packages/nuget.config"
            $fullCmd = $baseDotnetCommand + $nugetCmd
            Write-Verbose "[docker] $fullCmd"
            Invoke-Expression $fullCmd
        }
        'Remove Feed' {
            $nugetCmd = " nuget remove source $RemoveFeed"
            $nugetCmd += " --configfile /packages/nuget.config"
            $fullCmd = $baseDotnetCommand + $nugetCmd
            Write-Verbose "[docker] $fullCmd"
            Invoke-Expression $fullCmd
        }
        'Clean' {
            Get-Item $components -ErrorAction Ignore |
                Remove-Item -Recurse -Force -ErrorAction Ignore
            Write-Host 'Packages cleaned'
        }
        'Restore' {
            $envFile = Join-Path $envPath '.env'
            $runCmd = "docker run --rm -a stdout -a stderr -v '${components}:/components' -v '${packages}:/packages' --env-file '$envFile' $image"
            Write-Verbose "[docker]: $runCmd"
            Invoke-Expression $runCmd
        }
    }
}