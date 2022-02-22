#!/usr/bin/env pwsh
#Requires -Version 7

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [String]$Action

)

dynamicparam {
    $importedModule = Import-Module -Name ([IO.Path]::Combine($PSScriptRoot, 'powershell', 'cluedin.psm1')) -PassThru
    $scriptParams = $MyInvocation.MyCommand.Parameters.Keys
    $ciAction = Get-CluedInDynamicAction -Action $Action -Context 'docker' -ExistingParams $scriptParams
    if($ciAction) {
        return $ciAction.DynamicParams
    }
}

begin {
    if($ciAction) {
        foreach($boundParam in $PSBoundParameters.Keys) {
            if(-not ($ciAction.ParamNames -contains $boundParam)){
                $PSBoundParameters.Remove($boundParam) > $null
            }
        }
    }
}

process {
    if(-not $ciAction) {
        Write-Error "Unrecognized action: $Action"
    } else {
        Write-Information $ciAction.Header -InformationAction Continue
        & $ciAction.Command @PSBoundParameters
    }
}

end {
    Remove-Module -ModuleInfo $importedModule -Verbose:$false
}