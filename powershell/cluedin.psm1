using namespace System.Management.Automation

$script:emojiSupported = $IsLinux -or $IsMacOS -or ($IsWindows -and ($env:WT_SESSION -or $env:TERM_PROGRAM))

function Set-Environment {
    [OutputType([EnvironmentToggle])]
    [CmdletBinding()]
    param(
        [Hashtable]$Values = @{ }
    )

    return [EnvironmentToggle]::new($Values)
}

function Get-CluedInDynamicAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [String]$Action,
        [String[]]$ExistingParams = @()
    )

    $params = [RuntimeDefinedParameterDictionary]::new()
    $command = $null
    $header = [string]::Empty
    $commands = Get-Command -Module $MyInvocation.MyCommand.ModuleName
    foreach ($cmd in $commands) {
        if(!$cmd.ScriptBlock.Attributes) { continue }
        $found = $cmd.ScriptBlock.Attributes.Find({
            $args[0].TypeId.Name -eq 'CluedInAction' -and $args[0].Action -eq $Action
        })
        if ($found) {
            $command = $cmd
            $infoMessage = "CluedIn - $($found.Header -f $Action)"
            $wrapper = '+' + ('-' * ($infoMessage.Length + 2) ) + '+'
            $line = "| ${infoMessage} |"
            $header = $wrapper,$line,$wrapper -join [Environment]::NewLine
            break
        }
    }

    if ($command) {
        $paramNames = @()
        $command.Parameters.Values |
        ForEach-Object {
            $paramNames += $_.Name
            if ($_.Name -notin $ExistingParams) {
                $param = [RuntimeDefinedParameter]::new($_.Name, $_.ParameterType, $_.Attributes)
                $params.Add($param.Name, $param)
            }
        }

        return [PSCustomObject]@{
            Command       = $command.Name
            DynamicParams = $params
            ParamNames    = $paramNames
            Header        = $header
        }
    }

    return $null
}

# Entrypoint for sub scripts
$importArgs = @{
    Include = '*.ps1'
    Path    = Join-Path $PSScriptRoot '*'
}

Get-ChildItem @importArgs | Import-Module -Force

Export-ModuleMember *-*