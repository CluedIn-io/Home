function Test-Environment {
    [CmdletBinding()]
    [CluedInAction(Action = 'check', Header = 'Pre-Flight Check')]
    param(
        [String]$Env = 'default'
    )

    $cluedinDomain  = GetEnvironmentValue -Name $Env -Key 'CLUEDIN_DOMAIN' -DefaultValue 'localhost'

    $appChecks = [CheckCollection]::new('Installed Applications', @(
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
        }, 'Docker 19.0.0 or greater must be running with linux containers enabled.')

        [Check]::new('Docker Compose', {
            $info = docker-compose version --short
            $major,$minor,$patch = $info.Trim().Split('.')
            $success = ($major -ge 1) -and ($minor -ge 26)
            [CheckResult]::new($success, $info)
        }, 'You must be running docker-compose 1.26.0 or greater.')

    ))

    $portChecks = [CheckCollection]::new('Available Ports', @(
        [PortCheck]::new('CluedIn Web', 80, $cluedinDomain)
        [PortCheck]::new('CluedIn API', 9000, $cluedinDomain)
        [PortCheck]::new('CluedIn Auth', 9001, $cluedinDomain)
        [PortCheck]::new('CluedIn Dashboard', 9003, $cluedinDomain)
        [PortCheck]::new('CluedIn WebHook', 9006, $cluedinDomain)
        [PortCheck]::new('CluedIn Public', 9007, $cluedinDomain)
        [PortCheck]::new('CluedIn WebApi', 9008, $cluedinDomain)
    ))

    $authChecks = [CheckCollection]::new('Authentication', @(
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

    $envChecks = [CheckCollection]::new('Environment', @(
            [Check]::new('Docker - Memory', {
                $rawMemory = docker system info -f '{{json .MemTotal}}' | ConvertFrom-Json
                $intMemory = [Math]::Round($rawMemory / 1gb, 2)
                $state = if($intMemory -ge 16) { [CheckResultState]::Success } else { [CheckResultState]::Warning }
                $message = "${intMemory}gb available"
                [CheckResult]::new($state, $message)
            }, 'Docker should be configured with 16gb of available memory or more')
            [Check]::new('Docker - CPU', {
                $cpus = docker system info -f '{{json .NCPU}}' | ConvertFrom-Json
                $state = if($cpus -ge 2) { [CheckResultState]::Success } else { [CheckResultState]::Warning }
                $message = "${cpus} cpus available"
                [CheckResult]::new($state, $message)
            }, 'Docker should be configured with 2 cpus or more')
    ))


    CheckReport $appChecks,$portChecks,$authChecks,$envChecks
}

function Test-InstanceStatus {
    [CluedInAction(Action = 'status', Header = 'Status Check')]
    [CmdletBinding()]
    param(
        [String]$Env = 'default'
    )

    $domain  = GetEnvironmentValue -Name $Env -Key 'CLUEDIN_DOMAIN' -DefaultValue 'localhost'
    $port  = GetEnvironmentValue -Name $Env -Key 'CLUEDIN_SERVER_LOCALPORT' -DefaultValue '9000'

    $fullUri = "http://${domain}:${Port}/status"

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
