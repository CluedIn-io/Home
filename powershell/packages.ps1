$script:initConfig = @"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <add key="local" value="/packages/local" />
  </packageSources>
</configuration>
"@

function Invoke-Packages {
    [CluedInAction(Action = 'packages', Header = 'Packages')]
    [CmdletBinding(DefaultParameterSetName='list')]
    param(
        [Parameter(Position=0)]
        [string]$Env = 'default',
        [Parameter(ParameterSetName='list')]
        [switch]$List = $false,
        [Parameter(ParameterSetName='add', Mandatory)]
        [string]$Add,
        [Parameter(ParameterSetName='add')]
        [string]$Version = [string]::empty,
        [Parameter(ParameterSetName='remove', Mandatory)]
        [string]$Remove,
        [Parameter(ParameterSetName='addFeed', Mandatory)]
        [string]$AddFeed,
        [Parameter(ParameterSetName='addFeed', Mandatory)]
        [string]$Uri,
        [Parameter(ParameterSetName='addFeed')]
        [string]$User,
        [Parameter(ParameterSetName='addFeed')]
        [string]$Pass,
        [Parameter(ParameterSetName='removeFeed', Mandatory)]
        [string]$RemoveFeed,
        [Parameter(ParameterSetName='clean', Mandatory)]
        [switch]$Clean,
        [Parameter(ParameterSetName='restore', Mandatory)]
        [switch]$Restore,
        [Parameter(ParameterSetName='restore')]
        [Parameter(ParameterSetName='addFeed')]
        [Parameter(ParameterSetName='removeFeed')]
        [String]$Tag = [string]::Empty,
        [Parameter(ParameterSetName='restore')]
        [Parameter(ParameterSetName='addFeed')]
        [Parameter(ParameterSetName='removeFeed')]
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
        'add' {
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
        'remove' {
            $packageList = [array](ReadPackageList)
            $newList = $packageList | Where-Object { $_.Package -ne $Remove }

            Write-Host "Remove package ${Remove}"
            WritePackageList $newList
        }
        'list' {
            $packageList = [array](ReadPackageList)

            if($packageList.Count) {
                $packageList
            } else {
                Write-Host 'No packages specified'
            }
        }
        'addFeed' {
            $nugetCmd = " nuget add source $Uri -n $AddFeed"

            if($User) { $nugetCmd += " -u $User" }
            if($Pass) { $nugetCmd += " -p $Pass --store-password-in-clear-text" }

            $nugetCmd += " --configfile /packages/nuget.config"
            $fullCmd = $baseDotnetCommand + $nugetCmd
            Write-Verbose "[docker] $fullCmd"
            Invoke-Expression $fullCmd
        }
        'removeFeed' {
            $nugetCmd = " nuget remove source $RemoveFeed"
            $nugetCmd += " --configfile /packages/nuget.config"
            $fullCmd = $baseDotnetCommand + $nugetCmd
            Write-Verbose "[docker] $fullCmd"
            Invoke-Expression $fullCmd
        }
        'clean' {
            Get-Item $components -ErrorAction Ignore |
                Remove-Item -Recurse -Force -ErrorAction Ignore
            Write-Host 'Packages cleaned'
        }
        'restore' {
            $envFile = Join-Path $envPath '.env'
            $runCmd = "docker run --rm -a stdout -a stderr -v '${components}:/components' -v '${packages}:/packages' --env-file '$envFile' $image"
            Write-Verbose "[docker]: $runCmd"
            Invoke-Expression $runCmd
        }
    }
}