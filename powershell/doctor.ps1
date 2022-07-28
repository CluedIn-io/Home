class DoctorError
{
    [string]$Category
    [string]$ErrorMessage
    [string]$ErrorType

    DoctorError(
            [string]$category,
            [string]$errorMessage
    )
    {
        $this.Category = $category
        $this.ErrorMessage = $errorMessage
        $this.ErrorType = "WARNING"
    }

    DoctorError(
        [string]$category,
        [string]$errorMessage,
        [string]$errorType
    )
    {
        $this.Category = $category
        $this.ErrorMessage = $errorMessage
        $this.ErrorType = $errorType
    }
}

function Invoke-ClusterDoctor
{
    [CmdletBinding()]
    [CluedInAction(Action = 'doctor', Context = 'cluster', Header = 'Analyze a cluster for issues.')]
    Param(
        [string]$Env = 'default',
        [string]$Prefix = 'cluedin' # TODO: do we really need this?
    )

    $docterErrors = [System.Collections.ArrayList]@()

    SetClusterTools
    $environment = GetClusterEnvironment -Name $Env
    if (-not $environment)
    {
        Write-Host "--> Error: Could not find environment ${Env}"
        Write-Host "+----------------------------------------------------+"
        return
    }

    Write-Host "Tools"
    Write-Host "+----------------------------------------------------+"

    $k3dVersion = [System.Version]"4.4.1"
    $tfVersion = [System.Version]"0.14.9"
    $kubeVersion = [System.Version]"1.20.4"

    PrintTest "Tools" "Check K3D Executable" $(Test-Path $script:k3d.Command) "K3D NOT found. [$($script:k3d.Command)]" $true

    PrintTest "Tools" "Check K3D Version" $([System.Version]$script:k3d.Version -ge $k3dVersion) "K3D version need to be upgraded - Current:[$($script:k3d.Version)] Target: [$($k3dVersion)]"

    PrintTest "Tools" "Check Terraform Executable" $(Test-Path $script:terraform.Command) "Terraform NOT found. [$($script:terraform.Command)]" $true

    PrintTest "Tools" "Check Terraform Version" $([System.Version]$script:terraform.Version -ge $tfVersion) "Terraform version need to be upgraded - Current:[$($script:terraform.Version)] Target: [$($tfVersion)]"

    PrintTest "Tools" "Check Kubectl Executable" $(Test-Path $script:kubectl.Command) "Kubectl NOT found. [$($script:kubectl.Command)]" $true

    PrintTest "Tools" "Check Kubectl Version" $($script:kubectl.Version.StartsWith($kubeVersion)) "Kubectl version mis-match - Current:[$($script:kubectl.Version)] Target: [$($kubeVersion)]"

    Write-Host "+----------------------------------------------------+"
    Write-Host "Configuration"
    Write-Host "+----------------------------------------------------+"

    PrintTest "Configuration" "Check kubeconfig readable" $(Test-Path $Environment.KubeConfig) "Kubeconfig NOT found. [$($Environment.KubeConfig)]" $true

    $namespace = $environment.Variables['CLUEDIN_NAMESPACE']

    $commandOutput = InvokeCommand $script:kubectl.Command @('get', 'ns', $namespace, '-o=name', '--kubeconfig', $Environment.KubeConfig, '--ignore-not-found') -ErrorAction Ignore

    PrintTest "Configuration" "Check namespace [$namespace] is created" $($commandOutput -eq "namespace/$namespace") "Namespace [$namespace] not found. Please run 'prepare'." $true

    Write-Host "+----------------------------------------------------+"
    Write-Host "Detect CLUEDIN version"
    Write-Host "+----------------------------------------------------+"

    $commandOutput = InvokeCommand $script:kubectl.Command @('get', 'svc', "$prefix-cluedin", '--kubeconfig', $Environment.KubeConfig, '-n', $namespace, '-o=name', '--ignore-not-found') -ErrorAction Ignore

    if($commandOutput -eq "service/$prefix-cluedin")
    {
       $cluedinVersion = 320
    }
    else
    {
        $cluedinVersion = 322
    }

    Write-Host "| -> Cluedin Version: $cluedinVersion"

    Write-Host "+----------------------------------------------------+"
    Write-Host "Credentials"
    Write-Host "+----------------------------------------------------+"

    $commandOutput = InvokeCommand $script:kubectl.Command @('get', 'secret', '--kubeconfig', $Environment.KubeConfig, '-n', $namespace, "-o=jsonpath='{.items[*].metadata.name}'", '--ignore-not-found') -ErrorAction Ignore

    $dockerSecretName = $environment.Variables['CLUSTER_DOCKER_SECRET_NAME']
    $nugetSecretName = $environment.Variables['CLUSTER_NUGET_SECRET_NAME']
    $dockerSecret = $commandOutput | Select-String -Pattern $dockerSecretName -SimpleMatch -Raw
    $nugetSecret  = $commandOutput | Select-String -Pattern $nugetSecretName -SimpleMatch -Raw

    PrintTest "Credentials" "Check [$dockerSecretName] exists" $($dockerSecret -ne "") "Docker secret [$dockerSecretName] not found. Please run 'prepare'."
    PrintTest "Credentials" "Check [$nugetSecretName] exists" $($nugetSecret -ne "") "Nuget secret [$nugetSecretName] not found. Please run 'prepare'."

    $caCrt = Join-Path $environment.Certs 'ca.crt'
    $caKey = Join-Path $environment.Certs 'ca.key'

    if((Test-Path $caCrt) -and (Test-Path $caKey)) {

        $caSecretName = $environment.Variables['CLUSTER_CA_CERTIFICATE_SECRET_NAME']

        Write-Host "| -> Certificate Type : [ CA Certificate ]"

        $caSecret = $commandOutput | Select-String -Pattern $caSecretName -SimpleMatch -Raw

        PrintTest "Credentials" "Check [$caSecretName] exists" $($caSecret -ne "") "CA secret [$caSecretName] not found but certificate files found in directory. Please run 'prepare'."

        #TODO: CHECK ISSUER
    }

    $tlsCrt = Join-Path $environment.Certs 'tls.crt'
    $tlsKey = Join-Path $environment.Certs 'tls.key'

    $tlsSecretName = $environment.Variables['CLUSTER_TLS_CERTIFICATE_SECRET_NAME']

    if((Test-Path $tlsCrt) -and (Test-Path $tlsKey) -and -not(Test-Path $caCrt)) {
        Write-Host "| -> Certificate Type : [ SSL Certificate ]"

        $tlsSecret = $commandOutput | Select-String -Pattern $tlsSecretName -SimpleMatch -Raw

        PrintTest "Credentials" "Check [$tlsSecretName] exists" $($tlsSecret -ne "") "SSL secret [$tlsSecretName] not found but certificate files found in directory. Please run 'prepare'."
    }

    if((Test-Path $tlsCrt) -and (Test-Path $tlsKey) -and (Test-Path $caCrt) -and -not(Test-Path $caKey)) {
        Write-Host "| -> Certificate Type : [ SSL Certificate with Custom CA ]"

        $tlsSecret = $commandOutput | Select-String -Pattern $tlsSecretName -SimpleMatch -Raw

        PrintTest "Credentials" "Check [$tlsSecretName] exists" $($tlsSecret -ne "") "SSL+CA secret [$tlsSecretName] not found but certificate files found in directory. Please run 'prepare'."
    }

    Write-Host "+----------------------------------------------------+"
    Write-Host "Services - Infrastructure"
    Write-Host "+----------------------------------------------------+"

    $deployments = @()
    $statefulSets = @()

    $deployments320 = @("$prefix-openrefine","$prefix-sqlserver","$prefix-neo4j","$prefix-rabbitmq","$prefix-redis")
    $statefulSets320 = @("$prefix-elastic-master")

    $deployments322 = @('cluedin-openrefine','cluedin-sqlserver','cluedin-haproxy-ingress','cluedin-cert-manager','cluedin-cert-manager-webhook','cluedin-cert-manager-cainjector')
    $statefulSets322 = @('cluedin-rabbitmq','cluedin-elasticsearch','cluedin-neo4j-core','cluedin-redis-master')

    if($cluedinVersion -eq 320)
    {
        $deployments = $deployments320
        $statefulSets = $statefulSets320
    }
    else
    {
        $deployments = $deployments322
        $statefulSets = $statefulSets322
    }

    $monitoringEnabled = $environment.Variables['CLUEDIN_MONITORING_ENABLED']

    $monitoringDeployments = @('cluedin-grafana','cluedin-operator')
    $monitoringStatefulSets = @('prometheus-cluedin-prometheus','alertmanager-cluedin-alertmanager')

    if(($monitoringEnabled -eq 'true') -and ($cluedinVersion -ne 320))
    {
        $deployments = $deployments + $monitoringDeployments
        $statefulSets = $statefulSets + $monitoringStatefulSets
    }

    foreach($deployment in $deployments)
    {
        PrintTest "Infrastructure" "Check Deployment  [$deployment]" $(IsDeploymentReady $deployment $namespace $environment.KubeConfig) "Deployment [$deployment] not found or not ready."
    }

    foreach($set in $statefulSets)
    {
        PrintTest "Infrastructure" "Check StatefulSet [$set]" $(IsStatefulSetReady $set $namespace $environment.KubeConfig) "StatefulSet [$set] not found or not ready."
    }

    Write-Host "+----------------------------------------------------+"
    Write-Host "Services - Storage"
    Write-Host "+----------------------------------------------------+"

    $outputItems = InvokeCommand $script:kubectl.Command @('get', 'pvc', $deploymentName, '--kubeconfig', $Environment.KubeConfig, '-n', $namespace, '-o', 'json') -ErrorAction Ignore | ConvertFrom-Json -AsHashtable

    foreach($item in $outputItems.items)
    {
        PrintTest "Storage" "Check PersistentVolumeClaim [$($item.metadata.name)]" $($item.status.phase -eq "Bound")  "PersistentVolumeClaim [$($item.metadata.name)] not bound correctly."
    }

    Write-Host "+----------------------------------------------------+"
    Write-Host "Application - Services"
    Write-Host "+----------------------------------------------------+"

    $deployments = @()
    $statefulSets = @()

    $deployments320 = @("$prefix-webapi","$prefix-ui","$prefix-clean","$prefix-gql","$prefix-datasource","$prefix-annotation","$prefix-cluedin","$prefix-submitter")
    $deployments322 = @('cluedin-webapi','cluedin-ui','cluedin-prepare','cluedin-gql','cluedin-datasource','cluedin-annotation','cluedin-controller','cluedin-server','cluedin-submitter')

    if($cluedinVersion -eq 320)
    {
        $deployments = $deployments320
    }
    else
    {
        $deployments = $deployments322
    }

    foreach($deployment in $deployments)
    {
        PrintTest "Application" "Check Deployment  [$deployment]" $(IsDeploymentReady $deployment $namespace $environment.KubeConfig) "Deployment [$deployment] not found or not ready."
    }

    Write-Host "+----------------------------------------------------+"
    Write-Host "Ingress - Proxy"
    Write-Host "+----------------------------------------------------+"

    $ingressName = 'haproxy-ingress'
    if($cluedinVersion -gt 320)
    {
        $ingressName = "cluedin-${ingressName}"
    }

    $commandOutput = InvokeCommand $script:kubectl.Command @('get', 'svc', $ingressName, '--kubeconfig', $Environment.KubeConfig, '-n', $namespace, '-o', 'json', '--ignore-not-found') -ErrorAction Ignore | ConvertFrom-Json -AsHashtable
    PrintTest "Proxy" "Check HAProxy has IP" $($commandOutput.status.loadBalancer.ingress.count -gt 0) "HAProxy does NOT have an IP assigned."

    Write-Host "+----------------------------------------------------+"
    Write-Host "Application - API Status"
    Write-Host "+----------------------------------------------------+"

    if($docterErrors.Count -eq 0)
    {

        $domain = $environment.Variables['CLUEDIN_DOMAIN']

        $protocol = "http"

        $certPath = Join-Path $environment.Certs 'ca.crt'
        $tlsPath = Join-Path $environment.Certs 'tls.crt'

        if ((Test-Path $certPath) -or (Test-Path $tlsPath))
        {
            $protocol = "https"
        }

        $domain = $environment.Variables['CLUEDIN_DOMAIN']
        $organizationName = $environment.Variables['CLUEDIN_ORGANIZATION_NAME']
        $host = "${protocol}://${organizationName}.${domain}"

        try
        {
            $authApi = Invoke-Restmethod -Uri "$host/auth/api/status" 2> $null
            $apiApi = Invoke-Restmethod -Uri "$host/api/api/status" 2> $null
            $publicApi = Invoke-Restmethod -Uri "$host/public/api/status" 2> $null

            PrintTest "API" "Check Main API" $( $apiApi.ServiceStatus -eq 'Green' ) "Main API has status of [$( $apiApi.ServiceStatus )]"
            PrintTest "API" "Check Authentication API" $( $authApi.ServiceStatus -eq 'Green' ) "Auth API has status of [$( $authApi.ServiceStatus )]"
            PrintTest "API" "Check Public API" $( $publicApi.ServiceStatus -eq 'Green' ) "Public API has status of [$( $publicApi.ServiceStatus )]"
        }
        catch
        {
            PrintTest "API" "Check APIs" $false "Unable to contact API endpoints on host [$host]"
        }
    }
    else{
        Write-Host "| -> Skipped: Application not found."
    }

    if($cluedinVersion -gt 320)
    {
        Write-Host "+----------------------------------------------------+"
        Write-Host "Application - Organization Setup"
        Write-Host "+----------------------------------------------------+"

        $commandOutput = InvokeCommand $script:kubectl.Command @('get', 'orgs', '--kubeconfig', $Environment.KubeConfig, '-n', $namespace, '-o', 'json', '--ignore-not-found') -ErrorAction Ignore | ConvertFrom-Json -AsHashtable

        foreach ($organization in $commandOutput.items)
        {
            PrintTest "Organization" "Check organization [$( $organization.spec.name )]" $( $organization.status.phase -eq 'Active' ) "Organization [$( $organization.metadata.name )] not found or not active - Error: $( $organization.status.message )."
        }
    }

    PrintErrors($docterErrors)
}

function IsDeploymentReady
{
    param(
        [string]$deploymentName,
        [string]$namespace,
        [string]$kubeconfigPath
    )

    $output = InvokeCommand $script:kubectl.Command @('get', 'deployments', '--kubeconfig', $kubeconfigPath, '-n', $namespace, '--ignore-not-found') -ErrorAction Ignore
    $deploymentExists = $output | Select-String -Pattern $deploymentName -SimpleMatch -Raw

    if($deploymentExists)
    {
        $deployment = InvokeCommand $script:kubectl.Command @('get', 'deployment', $deploymentName, '--kubeconfig', $kubeconfigPath, '-n', $namespace, '-o', 'json') -ErrorAction Ignore | ConvertFrom-Json -AsHashtable

        $replicas = $deployment.spec.replicas
        $readyReplicas = $deployment.status.readyReplicas
        $unavailableReplicas = $deployment.status.unavailableReplicas

        if($replicas -eq "")
        {
            return $false
        }

        if($readyReplicas -eq "")
        {
            return $false
        }

        if($replicas -eq '0')
        {
            return $false
        }

        if($replicas -eq '0')
        {
            return $false
        }

        if ($unavailableReplicas -ge $replicas)
        {
            return $false
        }

        if ($readyReplicas -eq $replicas)
        {
            return $true
        }
    }

    return $false
}

function IsStatefulSetReady
{
    param(
        [string]$stsName,
        [string]$namespace,
        [string]$kubeconfigPath
    )

    $output = InvokeCommand $script:kubectl.Command @('get', 'sts', '--kubeconfig', $kubeconfigPath, '-n', $namespace, '--ignore-not-found') -ErrorAction Ignore
    $stsExists = $output | Select-String -Pattern $stsName -SimpleMatch -Raw

    if($stsExists)
    {
        $replicas = InvokeCommand $script:kubectl.Command @('get', 'sts', $stsName, '--kubeconfig', $kubeconfigPath, '-n', $namespace, '-o', "jsonpath='{.spec.replicas}'", '--ignore-not-found') -ErrorAction Ignore
        $readyReplicas = InvokeCommand $script:kubectl.Command @('get', 'sts', $stsName, '--kubeconfig', $kubeconfigPath, '-n', $namespace, '-o', "jsonpath='{.status.readyReplicas}'", '--ignore-not-found') -ErrorAction Ignore

        if($replicas -eq "")
        {
            return $false
        }

        if($readyReplicas -eq "")
        {
            return $false
        }

        if($replicas -eq '0')
        {
            return $false
        }

        if($replicas -eq '0')
        {
            return $false
        }

        if ($readyReplicas -eq $replicas)
        {
            return $true
        }
    }

    return $false
}

function PrintTest
{
    param(
        [String]$TestCategory,
        [String]$TestMessage,
        [Boolean]$TestResult,
        [String]$ErrorMessage,
        [Boolean]$fatalOnError
    )

    Write-Host "| -> $TestMessage [" -NoNewline

    if($TestResult) {
        Write-Host "OK]"
    }
    else{
        if($fatalOnError)
        {
            Write-Host "FATAL]"
            $docterErrors.Add([DoctorError]::new($TestCategory,$ErrorMessage,"FATAL")) | Out-Null
            PrintErrors
        }
        else
        {
            Write-Host "WARN]"
            $docterErrors.Add([DoctorError]::new($TestCategory,$ErrorMessage)) | Out-Null
        }
    }
}

function PrintErrors
{
    $isFatal = $false

    if($docterErrors.Count -gt 0)
    {
        Write-Host "+----------------------------------------------------+"
        Write-Host "Errors"
        Write-Host "+----------------------------------------------------+"
        $docterErrors | Format-Table -Property ErrorType, Category, ErrorMessage

        foreach ($error in $docterErrors)
        {
            $isFatal = $error.ErrorType -eq 'FATAL'
        }
    } else {
        Write-Host "+----------------------------------------------------+"
        Write-Host "No docterErrors found !"
        Write-Host "+----------------------------------------------------+"
    }

    if($isFatal)
    {
        exit 1
    }
}