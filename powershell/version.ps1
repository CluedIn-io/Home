function Invoke-Version {
    <#
        .SYNOPSIS
        Get version information for Home.

        .DESCRIPTION
        Verify the version of CluedIn Home that you are running.
        This information can be used to validate the version and
        commit you have checked out.
    #>
    [CmdletBinding()]
    [CluedInAction(Action = 'version', Header = 'Version')]
    param(
        [Switch]$Detailed = $false
    )

    Write-Host (git describe --tags --abbrev=7 --match v*)
    if($Detailed){
        $sha = git rev-parse HEAD
        (git rev-list --format=%B --max-count=1 $sha) | Write-Host
    }
}