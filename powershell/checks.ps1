function Test-Environment {
    <#
        .SYNOPSIS
        Tests environment configuration is acceptable for CluedIn.

        .DESCRIPTION
        Performs a series of checks against the host machine for required services (e.g. docker),
        performance concerns (e.g. available memory), and validates environment configuration
        (e.g. port availability).

        .EXAMPLE
        __AllParameterSets

        ```powershell
        > .\cluedin.ps1 check

        +----------------------------+
        | CluedIn - Pre-Flight Check |
        +----------------------------+
        Installed Applications
        [1/3] ✅ » PowerShell : 7.1.1 / Core
        [2/3] ✅ » Docker : 20.10.7 / linux
        [3/3] ✅ » Docker Compose : 1.29.2
        Available Ports
        [1/23] ✅ » CluedIn UI : 127.0.0.1.nip.io:9080
        [2/23] ✅ » CluedIn API : 127.0.0.1.nip.io:9000
        [3/23] ✅ » CluedIn Auth : 127.0.0.1.nip.io:9001
        [4/23] ✅ » CluedIn Jobs : 127.0.0.1.nip.io:9003
        [5/23] ✅ » CluedIn WebHooks : 127.0.0.1.nip.io:9006
        [6/23] ✅ » CluedIn Public : 127.0.0.1.nip.io:9007
        #...
        ```
    #>
    [CmdletBinding()]
    [CluedInAction(Action = 'check', Header = 'Pre-Flight Check')]
    param(
        # The environment in which CluedIn will run.
        [Parameter(Position=0)]
        [String]$Env = 'default'
    )

    $envDetails = GetEnvironment -Name $Env
    if(!$envDetails) {
        throw "Environment ${Env} could not be found"
    }

    $cluedinDomain = $envDetails.CLUEDIN_DOMAIN ?? 'localhost'

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
            $success = ($major -ge 2)
            [CheckResult]::new($success, $info)
        }, 'You must be running docker-compose v2 or greater. Ensure this is enabled in docker desktop.')

    ))

    $portChecks = [CheckCollection]::new('Available Ports', @(
        [PortCheck]::new('CluedIn UI', $envDetails.CLUEDIN_UI_LOCALPORT ?? 9080, $cluedinDomain)
        [PortCheck]::new('CluedIn API', $envDetails.CLUEDIN_SERVER_LOCALPORT ?? 9000, $cluedinDomain)
        [PortCheck]::new('CluedIn Auth', $envDetails.CLUEDIN_SERVER_AUTH_LOCALPORT ?? 9001, $cluedinDomain)
        [PortCheck]::new('CluedIn Jobs', $envDetails.CLUEDIN_SERVER_JOB_LOCALPORT ?? 9003, $cluedinDomain)
        [PortCheck]::new('CluedIn WebHooks', $envDetails.CLUEDIN_SERVER_WEBHOOK_LOCALPORT ?? 9006, $cluedinDomain)
        [PortCheck]::new('CluedIn Public', $envDetails.CLUEDIN_SERVER_PUBLIC_LOCALPORT ?? 9007, $cluedinDomain)
        [PortCheck]::new('CluedIn Web Api', $envDetails.CLUEDIN_WEBAPI_LOCALPORT ?? 9008, $cluedinDomain)
        [PortCheck]::new('CluedIn Clean', $envDetails.CLUEDIN_CLEAN_LOCALPORT ?? 9009, $cluedinDomain)
        [PortCheck]::new('CluedIn Annotation', $envDetails.CLUEDIN_ANNOTATION_LOCALPORT ?? 9010, $cluedinDomain)
        [PortCheck]::new('CluedIn Datasource', $envDetails.CLUEDIN_DATASOURCE_LOCALPORT ?? 9011, $cluedinDomain)
        [PortCheck]::new('CluedIn Submitter', $envDetails.CLUEDIN_SUBMITTER_LOCALPORT ?? 9012, $cluedinDomain)
        [PortCheck]::new('CluedIn Server Prometheus', $envDetails.CLUEDIN_SERVER_PROMETHEUS_METRICS_LOCALPORT ?? 9013, $cluedinDomain)
        [PortCheck]::new('CluedIn Datasource Prometheus Endpoint', $envDetails.CLUEDIN_DATASOURCE_PROMETHEUS_ENDPOINT_METRICS_LOCALPORT ?? 9014, $cluedinDomain)
        [PortCheck]::new('CluedIn Datasource Prometheus File', $envDetails.CLUEDIN_DATASOURCE_PROMETHEUS_FILE_METRICS_LOCALPORT?? 9015, $cluedinDomain)
        [PortCheck]::new('CluedIn Datasource Prometheus SQL', $envDetails.CLUEDIN_DATASOURCE_PROMETHEUS_SQL_METRICS_LOCALPORT ?? 9016, $cluedinDomain)
        [PortCheck]::new('CluedIn Documentation', $envDetails.CLUEDIN_DOCUMENTATION_LOCALPORT ?? 9021, $cluedinDomain)
        [PortCheck]::new('CluedIn Gql', $envDetails.CLUEDIN_GQL_LOCALPORT ?? 8888, $cluedinDomain)
        [PortCheck]::new('Neo4j Http', $envDetails.CLUEDIN_NEO4J_HTTP_LOCALPORT ?? 7474, 'localhost')
        [PortCheck]::new('Neo4j Bolt', $envDetails.CLUEDIN_NEO4J_BOLT_LOCALPORT ?? 7687, 'localhost')
        [PortCheck]::new('Elasticsearch Data', $envDetails.CLUEDIN_ELASTIC_DATA_LOCALPORT ?? 9200, 'localhost')
        [PortCheck]::new('Elasticsearch Http', $envDetails.CLUEDIN_ELASTIC_HTTP_LOCALPORT ?? 9300, 'localhost')
        [PortCheck]::new('RabbitMQ Data', $envDetails.CLUEDIN_RABBITMQ_DATA_LOCALPORT ?? 5672, 'localhost')
        [PortCheck]::new('RabbitMQ Http', $envDetails.CLUEDIN_RABBITMQ_HTTP_LOCALPORT ?? 15672, 'localhost')
        [PortCheck]::new('Redis', $envDetails.CLUEDIN_REDIS_LOCALPORT ?? 6379, 'localhost')
        [PortCheck]::new('Seq UI', $envDetails.CLUEDIN_SEQ_UI_LOCALPORT ?? 3200, 'localhost')
        [PortCheck]::new('Seq Data', $envDetails.CLUEDIN_SEQ_DATA_LOCALPORT ?? 5341, 'localhost')
        [PortCheck]::new('SMTP UI', $envDetails.CLUEDIN_SMTP_HTTP_LOCALPORT ?? 25258, 'localhost')
        [PortCheck]::new('SMTP Email', $envDetails.CLUEDIN_EMAIL_PORT ?? 2525, 'localhost')
        [PortCheck]::new('Sql Server', $envDetails.CLUEDIN_SQLSERVER_LOCALPORT ?? 1433, 'localhost')
        [PortCheck]::new('OpenRefine', $envDetails.CLUEDIN_OPENREFINE_LOCALPORT ?? 3333, 'localhost')
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
                'You must be authorized for the specified registry.')
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
    <#
        .SYNOPSIS
        Checks the health status of a running CluedIn instance.

        .DESCRIPTION
        Prints status of the CluedIn Docker containers.
        Additionally, requests the health status of a running CluedIn instance,
        reporting back a red/green status for each hosted web service and
        each data persistance service.

        .EXAMPLE
        __AllParameterSets

        ```powershell
        > .\cluedin.ps1 status

        +------------------------+
        | CluedIn - Status Check |
        +------------------------+
        Docker containers status

                        Name                              Command               State                                                                              Ports
        --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        cluedin_325_61ef0f49_annotation_1      docker-entrypoint.sh npm r ...   Up      0.0.0.0:9010->8888/tcp,:::9010->8888/tcp
        cluedin_325_61ef0f49_clean_1           docker-entrypoint.sh npm r ...   Up      0.0.0.0:9009->8888/tcp,:::9009->8888/tcp
        cluedin_325_61ef0f49_datasource_1      docker-entrypoint.sh npm r ...   Up      0.0.0.0:9011->8888/tcp,:::9011->8888/tcp
        cluedin_325_61ef0f49_documentation_1   docker-entrypoint.sh npm r ...   Up      0.0.0.0:9021->8888/tcp,:::9021->8888/tcp
        cluedin_325_61ef0f49_elasticsearch_1   /tini -- /usr/local/bin/do ...   Up      0.0.0.0:9200->9200/tcp,:::9200->9200/tcp, 0.0.0.0:9300->9300/tcp,:::9300->9300/tcp
        cluedin_325_61ef0f49_gql_1             docker-entrypoint.sh npm r ...   Up      0.0.0.0:8888->8888/tcp,:::8888->8888/tcp
        cluedin_325_61ef0f49_grafana_1         /run.sh                          Up      0.0.0.0:3030->3000/tcp,:::3030->3000/tcp
        cluedin_325_61ef0f49_neo4j_1           /sbin/tini -g -- /entrypoi ...   Up      7473/tcp, 0.0.0.0:7474->7474/tcp,:::7474->7474/tcp, 0.0.0.0:7687->7687/tcp,:::7687->7687/tcp
        cluedin_325_61ef0f49_openrefine_1      /app/refine                      Up      0.0.0.0:3333->3333/tcp,:::3333->3333/tcp
        cluedin_325_61ef0f49_prometheus_1      /bin/prometheus --web.enab ...   Up      0.0.0.0:9090->9090/tcp,:::9090->9090/tcp
        cluedin_325_61ef0f49_rabbitmq_1        docker-entrypoint.sh rabbi ...   Up      15671/tcp, 0.0.0.0:15672->15672/tcp,:::15672->15672/tcp, 25672/tcp, 4369/tcp, 5671/tcp, 0.0.0.0:5672->5672/tcp,:::5672->5672/tcp
        cluedin_325_61ef0f49_redis_1           docker-entrypoint.sh redis ...   Up      0.0.0.0:6379->6379/tcp,:::6379->6379/tcp
        cluedin_325_61ef0f49_seq_1             /run.sh                          Up      0.0.0.0:5341->5341/tcp,:::5341->5341/tcp, 0.0.0.0:3200->80/tcp,:::3200->80/tcp
        cluedin_325_61ef0f49_server_1          sh ./boot.sh                     Up      0.0.0.0:9000->9000/tcp,:::9000->9000/tcp, 0.0.0.0:9001->9001/tcp,:::9001->9001/tcp, 0.0.0.0:9003->9003/tcp,:::9003->9003/tcp,
                                                                                        0.0.0.0:9006->9006/tcp,:::9006->9006/tcp, 0.0.0.0:9007->9007/tcp,:::9007->9007/tcp, 0.0.0.0:9013->9013/tcp,:::9013->9013/tcp
        cluedin_325_61ef0f49_sqlserver_1       sh -c /init/init.sh              Up      0.0.0.0:1433->1433/tcp,:::1433->1433/tcp
        cluedin_325_61ef0f49_submitter_1       dotnet CluedIn.MicroServic ...   Up      0.0.0.0:9012->8888/tcp,:::9012->8888/tcp
        cluedin_325_61ef0f49_ui_1              /docker-entrypoint.sh /ent ...   Up      80/tcp, 0.0.0.0:9080->8080/tcp,:::9080->8080/tcp
        cluedin_325_61ef0f49_webapi_1          dotnet CluedIn.App.dll           Up      0.0.0.0:9008->9008/tcp,:::9008->9008/tcp

        Running CluedIn instance status

        Can Connect
        [1/1] ✅ » Is Up : http://127.0.0.1.nip.io:9000/status
        DataShards
        [1/6] ✅ » Blob
        [2/6] ✅ » Configuration
        [3/6] ✅ » Data
        [4/6] ✅ » Search
        [5/6] ✅ » Graph
        [6/6] ✅ » Metrics
        Components
        [1/6] ✅ » Api
        [2/6] ✅ » Authentication
        [3/6] ✅ » Crawling
        [4/6] ✅ » Scheduling
        [5/6] ✅ » ServiceBus
        [6/6] ✅ » System
        #...
        ```
    #>
    [CluedInAction(Action = 'status', Header = 'Status Check')]
    [CmdletBinding()]
    param(
        # The environment in which CluedIn is running.
        [Parameter(Position=0)]
        [String]$Env = 'default',
        # Return basic status information only
        [Switch]$Brief = $false
    )

    Write-Host "Docker containers status" -ForegroundColor DarkYellow
    Write-Host
    DockerCompose -Action 'ps --all' -Env $Env
    Write-Host

    if($Brief) {
        return
    }

    Write-Host "Running CluedIn instance status" -ForegroundColor DarkYellow
    Write-Host
    $fallbackDomain = GetEnvironmentValue -Name $Env -Key 'CLUEDIN_DOMAIN' -DefaultValue 'localhost'
    $domain  = GetEnvironmentValue -Name $Env -Key 'CLUEDIN_SERVER_HOST' -DefaultValue $fallbackDomain
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
                    $success = switch ($info) {
                        'green' { [CheckResultState]::Success }
                        'yellow' { [CheckResultState]::Warning }
                        'red' { [CheckResultState]::Error }
                        default { [CheckResultState]::Warning }
                    }
                    [CheckResult]::new($success, [string]::Empty)
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
