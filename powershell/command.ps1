function InvokeCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Command,
        [object[]]$ArgumentList = @(),
        [hashtable]$EnvironmentVariables = @{}
    )

    $envContext = Set-Environment $EnvironmentVariables
    try {
        $global:LASTEXITCODE = 0 # Make sure we set the value in the correct scope
        & $Command $ArgumentList
        if($global:LASTEXITCODE -ne 0) {
            Write-Error "The ${Command} command did not exit successfully"
        }
    } finally {
        $envContext.Reset()
    }
}