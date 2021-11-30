using namespace System.Management.Automation
using namespace System.IO
using namespace System.Collections.Generic

enum CheckResultState {
    Success
    Failure
    Warning

}

class CheckResult {
    [CheckResultState]$State
    [String]$Details
    [String]$Name
    [String]$FailMessage

    CheckResult([CheckResultState]$State) {
        $this.State = $State
    }

    CheckResult([CheckResultState]$State, [String]$Details) {
        $this.State = $State
        $this.Details = $Details
    }

    CheckResult([Boolean]$Success) {
        $this.State = $Success ? [CheckResultState]::Success : [CheckResultState]::Failure
    }

    CheckResult([Boolean]$Success, [String]$Details) {
        $this.State = $Success ? [CheckResultState]::Success : [CheckResultState]::Failure
        $this.Details = $Details
    }

    [void] Print() {
        if($script:emojiSupported) {
            $symbol = switch($this.State){
                ([CheckResultState]::Success.ToString()) { '✅'; break }
                ([CheckResultState]::Failure.ToString()) { '❌'; break }
                ([CheckResultState]::Warning.ToString()) { '⚠️ '; break }
            }
            Write-Host $symbol -NoNewline
        } else {
            switch($this.State){
                ([CheckResultState]::Success.ToString()) {
                    Write-Host "`u{221A}" -ForegroundColor Green -NoNewline; break
                }
                ([CheckResultState]::Failure.ToString()) {
                    Write-Host "`u{00D7}" -ForegroundColor Red -NoNewline; break
                }
                ([CheckResultState]::Warning.ToString()) {
                    Write-Host "`u{203C}" -ForegroundColor Yellow -NoNewline; break
                }
            }
        }
        $line = " `u{00BB} $($this.Name)"
        if($this.Details) {
            $line += " : $($this.Details)"
        }
        Write-Host $line
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

    [CheckResult] Run() {
        try {
            $this.Result = $this.Action.InvokeReturnAsIs($this)
        }
        catch {
            $this.Result = [CheckResult]::new([CheckResultState]::Failure)
        }

        $this.Result.Name = $this.Name
        $this.Result.FailMessage = $this.FailMessage
        return $this.Result
    }
}

class PortCheck : Check {
    [Int]$Port
    [String]$Domain = 'localhost'

    PortCheck([String]$Name, [Int]$Port, [String]$Domain) : base($Name, {
            $info = Test-Connection -ComputerName $args[0].Domain -TcpPort $args[0].Port -WarningAction Ignore -TimeoutSeconds 1
            $success = -not [Boolean]::Parse($info)
            [CheckResult]::new($success, "$($args[0].Domain):$($args[0].Port)")
        }, "The specified port must be available." ) {

        $this.Domain = $Domain
        $this.Port = $Port
    }
}

class CheckCollection {
    [Parameter(Mandatory)]
    [String]$Name
    [Parameter(Mandatory)]
    [Check[]]$Checks
    hidden [List[CheckResult]]$FailedChecks = [List[CheckResult]]::new()

    CheckCollection([String]$Name, [Check[]]$Checks) {
        $this.Name = $Name
        $this.Checks = $Checks
    }

    [int] Run() {
        Write-Host "$($this.Name)"
        $count = $this.Checks.Count
        for ($i = 0; $i -lt $count; $i++) {
            $check = $this.Checks[$i]
            $result = $check.Run()
            Write-Host "  [$($i+1)/${count}] " -NoNewline
            $result.Print()

            if($result.State -ne [CheckResultState]::Success) {
                $this.FailedChecks.Add($result)
            }
        }

        return $this.FailedChecks.Count
    }

    [void] ReportErrors() {
        foreach($result in $this.FailedChecks) {
           $result.Print()
           Write-Host "     $($result.FailMessage)"
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
        if($script:emojiSupported) {
            Write-Host "🚧 [${errorCount}] check(s) failed. Please review for solutions:" -ForegroundColor Red
        } else {
            Write-Host "`u{2736} [${errorCount}] check(s) did not succeed. Please review for solutions:" -ForegroundColor Red
        }
        foreach ($collection in $CheckCollections) {
            $collection.ReportErrors()
        }
    }
}

class CluedInAction : Attribute {
    [string]$Action = @()
    [string]$Header = [string]::Empty
    [string]$Context = "docker"
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
        Set-Item $path.ToUpper() $Value
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
    static [string]$Env
    static [string]$ClusterEnv
    static [string]$TerraformScripts

    static [string] EnvironmentForContext([string] $context) {
        $result = switch ($context) {
            docker { [Paths]::Env }
            cluster { [Paths]::ClusterEnv }
            default {
                throw "Unknown context '$context'"
            }
        }

        return $result
    }

    static [void] InitPaths([string] $scriptsDir) {
        [Paths]::Env              = (Get-Item ([Path]::Combine($scriptsDir, '..', 'env'))).FullName
    }
}

# .NET implementation of string hash code copied from here:
# https://stackoverflow.com/a/36845864/2009373
$StringHashesClass = @"
    public class StringHashes
    {
        public static int GetStableHashCode(string str)
        {
            unchecked
            {
                int hash1 = 5381;
                int hash2 = hash1;

                for(int i = 0; i < str.Length && str[i] != '\0'; i += 2)
                {
                    hash1 = ((hash1 << 5) + hash1) ^ str[i];
                    if (i == str.Length - 1 || str[i+1] == '\0')
                        break;
                    hash2 = ((hash2 << 5) + hash2) ^ str[i+1];
                }

                return hash1 + (hash2*1566083941);
            }
        }
    }
"@
Add-Type -TypeDefinition $StringHashesClass
