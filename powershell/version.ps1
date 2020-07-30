function Invoke-Version {
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