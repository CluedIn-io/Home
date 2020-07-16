using namespace System.Management.Automation
using namespace System.IO
using namespace System.Collections.Generic

class CheckResult {
    [Boolean]$Success
    [String]$Details

    CheckResult([Boolean]$Success) {
        $this.Success = $Success
    }

    CheckResult([Boolean]$Success, [String]$Details) {
        $this.Success = $Success
        $this.Details = $Details
    }
}

class Check {
    [Parameter(Mandatory)]
    [String]$Name
    [Parameter(Mandatory)]
    [Scriptblock]$Action
    [Parameter(Mandatory)]
    [String]$FailMessage
    [PSObject]$Data = @{ }
    [CheckResult]$Result

    Check([String]$Name, [Scriptblock]$Action, [String]$FailMessage) {
        $this.Name = $Name
        $this.Action = $Action
        $this.FailMessage = $FailMessage
    }

    Check([String]$Name, [PSObject]$Data, [Scriptblock]$Action, [String]$FailMessage) {
        $this.Name = $Name
        $this.Data = $Data
        $this.Action = $Action
        $this.FailMessage = $FailMessage
    }

    [bool] Run() {
        try {
            $this.Result = $this.Action.InvokeReturnAsIs($this)
        }
        catch {
            $this.Result = [CheckResult]::new($false)
        }

        return $this.Result.Success
    }

    [String] Report() {
        $line = "$($this.Result.Success ? '✅' : '❌') => $($this.Name)"
        if ($this.Result.Details) { $line += " : $($this.Result.Details)" }
        return $line
    }
}

class PortCheck : Check {
    [Int]$Port

    PortCheck([String]$Name, [Int]$Port) : base($Name, {
            $info = Test-Connection -ComputerName localhost -TcpPort $args[0].Port -WarningAction Ignore
            $success = -not [Boolean]::Parse($info)
            [CheckResult]::new($success, "")
        }, "The specified port must be available." ) {

        $this.Port = $Port
    }
}

class CheckCollection {
    [Parameter(Mandatory)]
    [String]$Name
    [Parameter(Mandatory)]
    [Check[]]$Checks
    hidden [List[Check]]$FailedChecks = [List[Check]]::new()

    CheckCollection([String]$Name, [Check[]]$Checks) {
        $this.Name = $Name
        $this.Checks = $Checks
    }

    [int] Run() {
        Write-Host "Checking $($this.Name)"
        $count = $this.Checks.Count
        for ($i = 0; $i -lt $count; $i++) {
            $check = $this.Checks[$i]
            $success = $check.Run()
            Write-Host "  [$($i+1)/${count}] " -NoNewline
            Write-Host $check.Report()

            if(-not $success) {
                $this.FailedChecks.Add($check)
            }
        }

        return $this.FailedChecks.Count
    }

    [void] ReportErrors() {
        foreach($check in $this.FailedChecks) {
           Write-Host $check.Report()
           Write-Host $check.FailMessage
        }
    }
}

function CheckReport {
    param(
        [Parameter(Mandatory)]
        [CheckCollection[]]$CheckCollections
    )

    $errorCount = 0
    foreach($collection in $CheckCollections) {
        $errorCount += $collection.Run()
    }

    if($errorCount -gt 0) {
        Write-Host ''
        Write-Host "🚧 [${errorCount}] check(s) failed. Please review for solutions:" -ForegroundColor Red
        foreach ($collection in $CheckCollections) {
            $collection.ReportErrors()
        }
    }
}

class CluedInAction : Attribute {
    [string]$Action = @()
    [string]$Header = [string]::Empty
}

class EnvironmentToggle {
    hidden [Hashtable]$Container = @{ }

    EnvironmentToggle([Hashtable]$Values) {
        foreach ($key in $Values.Keys) {
            $this.Set($key, $Values[$key])
        }
    }

    [void] Set([String]$Variable, [String]$Value) {
        $path = "env:$Variable"
        if (-not($this.Container.Keys -contains $Variable)) {
            $current = Get-Item $path -ErrorAction Ignore
            if (-not $current) { $current = $null }
            else { $current = $current.Value }
            $this.Container[$Variable] = $current
        }
        Set-Item $path $Value
    }

    [void] Reset() {
        foreach ($key in $this.Container.Keys) {
            $path = "env:$key"
            Set-Item $path $this.Container[$key]
        }

        $this.Container = @{ }
    }
}

class Paths {
    static [string]$Env = (Get-Item ([Path]::Combine($PSScriptRoot, 'env'))).FullName
}