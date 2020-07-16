function Test-Environment {
    [CmdletBinding()]
    [CluedInAction(Action = 'check', Header = 'Pre-Flight Check')]
    param()

    $apps = [CheckCollection]::new('Installed Applications', @(
        [Check]::new('PowerShell', {
            $message = "$($PSVersionTable.PSVersion) / $($PSVersionTable.PSEdition)"
            $success = $PSVersionTable.PSVersion.Major -ge 7 -and $PSVersionTable.PSEdition -eq 'Core'
            [CheckResult]::new($success, $message)
        }, 'You must have Powershell Core 7.0.0 or greater installed.')

        [Check]::new('Docker', {
            $info = docker version -f '{{json .}}' | ConvertFrom-Json
            $client = ($info.Client.Version -replace '\..*', '') -ge 19
            $server = try { $info.Server.Components[0].Details.os -eq 'linux' } catch { $false }
            $success = $client -and $server
            $message = $info.Client.Version
            if($server) {
                $message += " / $($info.Server.Components[0].Details.os)"
            }
            [CheckResult]::new($success, $message)
        }, 'You must be running docker 19.0.0 or greater with linux containers enabled.')

        [Check]::new('Docker Compose', {
            $info = docker-compose version --short
            $success = ($info -replace '\..*', '') -ge 1
            [CheckResult]::new($success, $info)
        }, 'You must be running docker-compose 1.0.0 or greater.')

    ))

    $ports = [CheckCollection]::new('Available Ports', @(
        [PortCheck]::new('CluedIn Web', 80)
        [PortCheck]::new('CluedIn API', 9000)
        [PortCheck]::new('CluedIn Auth', 9001)
        [PortCheck]::new('CluedIn Dashboard', 9003)
        [PortCheck]::new('CluedIn WebHook', 9006)
        [PortCheck]::new('CluedIn Public', 9007)
        [PortCheck]::new('CluedIn WebApi', 9008)
    ))

    $auth = [CheckCollection]::new('Authentication', @(
            [Check]::new('Docker Registry',
                @{ Registry = 'https://index.docker.io/v1/' },
                {
                    $info = (Get-Content ~/.docker/config.json | ConvertFrom-Json).auths.psobject.properties.Name
                    $success = $info -contains $args[0].Data.Registry
                    $message = $args[0].Data.Registry
                    [CheckResult]::new($success, $message)
                },
                'You must be authorised for the specified registry.')
    ))

    CheckReport $apps,$ports,$auth
}

function Test-InstanceStatus {
    [CluedInAction(Action = 'status', Header = 'Status Check')]
    [CmdletBinding()]
    param(
        [String]$Uri = 'http://localhost',
        [Int]$Port = 9000
    )

    $fullUri = "${Uri}:${Port}/status"

    # Get Response Data
    $response = $null
    $status = $true

    try {
        $response = Invoke-RestMethod $fullUri
    }
    catch {
        if ($_.Exception -is [Microsoft.PowerShell.Commands.HttpResponseException]) {
            $response = $_.ErrorDetails.Message | ConvertFrom-Json
        }
        else {
            $status = $false
        }
    }

    function ComposeCheck {
        param(
            [Parameter(ValueFromPipeline)]
            $details
        )

        process {
            [Check]::new($details.Type,
                $details,
                {
                    $info = $args[0].Data.ServiceStatus
                    $success = $info -eq 'green'
                    [CheckResult]::new($success, "")
                },
                "Service status should be 'Green'"
            )
        }
    }

    $checks = @()
    $checks += [CheckCollection]::new('Can Connect', @(
        [Check]::new('Is Up',
            @{ Uri = $fullUri; Status = $status },
            {
                [CheckResult]::new($args[0].Data.Status, "$($args[0].Data.Uri)")
            },
            "Could not connect to ${fullUri}"
        )
    ))

    if ($response) {
        $checks += [CheckCollection]::new('DataShards', ($response.DataShards | ComposeCheck))
        $checks += [CheckCollection]::new('Components', ($response.Components | ComposeCheck))
    }

    CheckReport $checks
}
