$script:kubectl = $null
$script:k3d = $null
$script:terraform = $null
$script:emailRegex = '[^@\s]+@[^@\s]+(\.[^@\s])+'

function SetClusterTools {

    function GetClusterTool {
        param(
            [Parameter(Mandatory)]
            [string]$Name,
            [scriptblock]$SetVersion
        )

        $commandPath = if($onPath = Get-Command $Name -ErrorAction Ignore) {
                         $onPath.Path
                       } else {
                         $os = $PSVersionTable.OS -replace '[^\w].*',''
                         Join-Path $PSScriptRoot '..' 'terraform' 'bin' ($os.ToLower()) $commandName
                       }

        [PSCustomObject]@{
            Command = $commandPath
            Version = [string]$SetVersion.Invoke($commandPath)
        }
    }

    $script:kubectl = GetClusterTool kubectl {
        $kubectlArgs = @(
            'version'
            '--short=true'
            '--client=true'
        )

        $version = InvokeCommand $commandPath $kubectlArgs | Select-String -Pattern 'Client Version' -SimpleMatch -Raw | ForEach-Object {
            $_.split(" ")[2]
        }
        return $null -eq $Version ? "Unknown" : $version.SubString(1)
    }

    $script:k3d = GetClusterTool k3d {
        $version = InvokeCommand $commandPath version | Select-String -Pattern 'k3d version' -SimpleMatch -Raw | ForEach-Object {
            $_.split(" ")[2]
        }

        return $null -eq $Version ? "Unknown" : $version.SubString(1)
    }

    $script:terraform = GetClusterTool terraform {
        $version = InvokeCommand $commandPath @('version', '-json') | ConvertFrom-Json | ForEach-Object terraform_version
        return $version ?? 'Unknown'
    }

    $k3dWarning = ""

    if([System.Version]$k3d.Version -lt [System.Version]"5.1.0") {
        $k3dWarning = "[PLEASE UPDATE]"
    }

    $tfWarning = ""

    if([System.Version]$terraform.Version -lt [System.Version]"1.0.0") {
        $tfWarning = "[PLEASE UPDATE]"
    }

    $kubeWarning = ""

    if([System.Version]$kubectl.Version -lt [System.Version]"1.21.0") {
        $kubeWarning = "[PLEASE UPDATE]"
    }

    Write-Host "--> K3D       : $($k3d.Version) @ $($k3d.Command) $($k3dWarning)"
    Write-Host "--> Terraform : $($terraform.Version) @ $($terraform.Command) $($tfWarning)"
    Write-Host "--> Kubectl   : $($kubectl.Version) @ $($kubectl.Command) $($kubeWarning)"
    Write-Host "+----------------------------------------------------+"
}

function WriteComplete {
    param(
        [string]$Extra
    )

    Write-Host ".. Done"
    if($Extra) {
        Write-Host "+----------------------------------------------------+"
        Write-Host $Extra
    }
    Write-Host "+----------------------------------------------------+"
    Write-Host "--> COMPLETE !"
    Write-Host "+----------------------------------------------------+"
}

function GetClusterEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $envPath = $Name | FindEnvironment -Context 'cluster'
    if(-not $envPath) {
        Write-Host "--> Error: Could not find environment ${Name}"
        Write-Host "+----------------------------------------------------+"
        return
    }

    [PSCustomObject]@{
        Name = $Name
        Path = $envPath
        Variables = GetEnvironment -Name $Name -Context 'cluster'
        ClusterName = "cluedin-${Name}"
        KubeConfig = Join-Path $envPath 'kubeconfig'
        Certs = Join-Path $envPath 'certs'
    }

}

function GetTerraformEnvrionment {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$ClusterEnvironment,
        [Parameter(Mandatory)]
        [string]$Context
    )

    $dataDir = New-Item (Join-Path ([Paths]::ClusterEnv) '.terraform') -ItemType Directory -Force
    $stateDir = (Join-Path $ClusterEnvironment.Path 'terraform' "${Context}.json").Replace('\','/')
    $tfEnvironment = @{
        #TF_LOG = 'DEBUG'
        TF_INPUT = $false # disable user input - everything should come from vars
        TF_IN_AUTOMATION = $true # adjust output to avoid suggesting next steps
        TF_DATA_DIR = $dataDir.FullName.Replace('\','/')
        TF_VAR_environment_path = $ClusterEnvironment.Path
        TF_CLI_ARGS_apply="-state=${stateDir}"
        TF_CLI_ARGS_destroy="-state=${stateDir}"
        TF_CLI_ARGS_output="-state=${stateDir}"
    }
    $ClusterEnvironment.Variables.Keys | ForEach-Object {
        $tfEnvironment["TF_VAR_$($_.ToLower())"] = $ClusterEnvironment.Variables[$_]
    }

    $tfEnvironment
}

function ClusterExists {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $commandArgs = @( 'cluster', 'list', '-o', 'json')
    InvokeCommand $k3d.Command $commandArgs | ConvertFrom-Json | Where-Object {$_.Name -eq $Name }
}

function GetOrRequestVariable {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Environment,
        [Parameter(Mandatory)]
        [string]$Variable,
        [Parameter(Mandatory)]
        [string]$Message,
        [switch]$MaskInput,
        [switch]$BoolResponse
    )

    $value = $Environment.Variables[$Variable]

    if(-not $value) {
        if($BoolResponse) { $Message += ' (yes/no)' }
        $validResponse = $false
        do{
            $value = Read-Host $message -MaskInput:$MaskInput
            if($BoolResponse) {
                $value = switch ($value) {
                    'yes' { 'true' }
                    'no' { 'false' }
                    default { $null }
                }
            }
            $validResponse = (-not $BoolResponse) -or ($null -ne $value)
        } until ($validResponse)


        InvokeEnvironment -Name $Environment.Name -Context 'cluster' -Set "$Variable=$value"
        $Environment.Variables[$Variable] = $value
    }

    return $value
}

function Invoke-ClusterEnvironment {
    [CmdletBinding()]
    [CluedInAction(Action = 'env', Context = 'cluster', Header = 'Configure cluster environment')]
    param(
        [Parameter(Position=0, ParameterSetName='set')]
        [Parameter(Position=0, ParameterSetName='setTag')]
        [Parameter(Position=0, ParameterSetName='get')]
        [Parameter(Position=0, ParameterSetName='unset')]
        [Parameter(Position=0, ParameterSetName='remove')]
        [string]$Name = 'default',
        [Parameter(ParameterSetName='set', Mandatory)]
        [string[]]$Set,
        [Parameter(ParameterSetName='set')]
        [Parameter(ParameterSetName='setTag', Mandatory)]
        [string]$Tag = [string]::Empty,
        [Parameter(ParameterSetName='set')]
        [Parameter(ParameterSetName='setTag')]
        [Parameter(ParameterSetName='get')]
        [switch]$Get,
        [Parameter(ParameterSetName='unset',Mandatory)]
        [string[]]$Unset,
        [Parameter(ParameterSetName='remove',Mandatory)]
        [Alias('rm')]
        [switch]$Remove
    )

    process {

        # Base args to match to inner calls
        $innerArgs = @{
            Context = 'cluster'
            Name = $Name
        }

        switch ($PSCmdlet.ParameterSetName) {
            {$_ -in @('set', 'setTag')} {
                InvokeEnvironment @innerArgs -Set $Set -SetCustom {

                    ### $env is injected into the scope of this block ###
                    # Update tags
                    if($Tag) {
                        $keys = [string[]]::new($env.Keys.Count)
                        $env.Keys.CopyTo($keys, 0)
                        foreach ($key in $keys) {
                            if($key -match '(\w+)_IMAGE_VERSION'){
                                Write-Host "Setting '${key}' in '$Name' environment"
                                $env[$key] = $Tag
                            }
                        }
                    }
                }
            }
            'get' {
                InvokeEnvironment @innerArgs
            }
            'unset' {
                InvokeEnvironment @innerArgs -Unset $Unset
            }
            'remove' {
                InvokeEnvironment @innerArgs -Remove
            }
        }
    }
}

function Invoke-ClusterInit {
    [CmdletBinding()]
    [CluedInAction(Action = 'init', Context = 'cluster', Header = 'Initialize a local K3D cluster')]
    Param(
        [string]$Env = 'default'
    )

    SetClusterTools
    $environment = GetClusterEnvironment -Name $Env
    if(-not $environment) { return }

    #Check if cluster exists
    if(ClusterExists  $environment.ClusterName){
        Write-Host "--> Skipping: Cluster [$($environment.ClusterName)] already exists."
        Write-Host "+----------------------------------------------------+"
        return
    }

    # Check if kubeconfig exists
    if(Test-Path $environment.KubeConfig) {
        Write-Host "--> Skipping: Kubeconfig found."
        Write-Host "+----------------------------------------------------+"
        return
    }

    Write-Host "Creating cluster please wait .." -NoNewline

    $k3dArgs = @(
        'cluster', 'create', $environment.ClusterName
        '--image', $environment.Variables.K3D_K3S_VERSION,
        '--servers', $environment.Variables.K3D_SERVER_COUNT
        '--agents', $environment.Variables.K3D_AGENT_COUNT
        '-p', '80:80@loadbalancer'
        '-p', '443:443@loadbalancer'
        '--k3s-arg', '--disable=traefik@server:0'
    )
    Write-Verbose "K3D: $($k3dArgs)"
    InvokeCommand $k3d.Command $k3dArgs -ErrorAction Stop | Write-Verbose

    $k3dArgs = @(
        'kubeconfig', 'merge', $environment.ClusterName
        '-o', $environment.KubeConfig
        '--overwrite'
    )
    Write-Verbose "K3D: $($k3dArgs)"
    InvokeCommand $k3d.Command $k3dArgs -ErrorAction Stop | Write-Verbose

    WriteComplete -Extra "--> Kubeconfig path: $($environment.KubeConfig)"
}

function Invoke-ClusterClean {
    [CmdletBinding()]
    [CluedInAction(Action = 'clean', Context = 'cluster', Header = 'Remove any temporary files')]
    Param(
        [string]$Env = 'default'
    )

    SetClusterTools
    $environment = GetClusterEnvironment -Name $Env
    if(-not $environment) { return }

    Write-Host "--> Cleaning Terraform state files.." -NoNewLine

    $stateDir = (Join-Path $environment.Path 'terraform')

    Get-ChildItem ($stateDir) | ForEach-Object {
        Remove-Item $_
        Write-Host ".." -NoNewline
    }

    Write-Host ".. Done"

    Write-Host "--> Cleaning Terraform cache files.." -NoNewLine

    $dataDir = Join-Path ([Paths]::ClusterEnv) '.terraform'
    Remove-Item $dataDir -Recurse -Force -ErrorAction Ignore

    Write-Host ".." -NoNewline

    Get-ChildItem ([Paths]::TerraformScripts) | ForEach-Object {
        Push-Location $_
        try{
            Remove-Item 'terraform*'
            Remove-Item '.terraform*' -Recurse -Force
        } finally {
            Pop-Location
        }
        Write-Host ".." -NoNewline
    }

    WriteComplete
}

function Invoke-ClusterDestroy {
    [CmdletBinding()]
    [CluedInAction(Action = 'destroy', Context = 'cluster', Header = 'Destroy a local K3D cluster')]
    Param(
        [string]$env = 'default'
    )

    SetClusterTools
    $environment = GetClusterEnvironment -Name $Env
    if(-not $environment) { return }


    #Check if cluster exists
    if(-not (ClusterExists $environment.ClusterName)){
        Write-Host "--> Skipping: Cluster [$($environment.ClusterName)] not found."
        Write-Host "+-------------------------------------------------+"
        return
    }

    Write-Host "--> Deleting cluster.." -NoNewLine

    # Remove Cluster
    $k3dArgs = @('cluster', 'delete', $environment.ClusterName)
    Write-Verbose "K3D: ${k3dArgs}"
    InvokeCommand $k3d.Command $k3dArgs | Write-Verbose

    # Remove kubeconfig

    Remove-Item $environment.KubeConfig -ErrorAction Ignore

    WriteComplete
}

function Invoke-ClusterPrepare {
    [CmdletBinding()]
    [CluedInAction(Action = 'prepare', Context = 'cluster', Header = 'Install credentials into cluster')]
    Param(
        [string]$Env = 'default',
        [Switch]$Force
    )

    SetClusterTools
    $environment = GetClusterEnvironment -Name $Env
    if(-not $environment) { return }

    if(!(Test-Path $environment.KubeConfig)) {
        Write-Host "--> Error: Kubeconfig NOT found. [$($environment.KubeConfig)]"
        Write-Host "+----------------------------------------------------+"
        return
    }

    GetOrRequestVariable $environment 'CLUSTER_DOCKER_USERNAME' -Message 'Please enter your dockerhub username' | Out-Null
    GetOrRequestVariable $environment 'CLUSTER_DOCKER_PASSWORD' -Message 'Please enter your dockerhub password' -MaskInput | Out-Null
    GetOrRequestVariable $environment 'CLUSTER_NUGET_TOKEN' -Message 'Please enter your Nuget PAT token' -MaskInput | Out-Null

    $caCrt = Join-Path $environment.Certs 'ca.crt'
    $caKey = Join-Path $environment.Certs 'ca.key'

    if((Test-Path $caCrt) -and (Test-Path $caKey)) {
        Write-Host "--> Found: CA Certificate"
    }

    $tlsCrt = Join-Path $environment.Certs 'tls.crt'
    $tlsKey = Join-Path $environment.Certs 'tls.key'

    if((Test-Path $tlsCrt) -and (Test-Path $tlsKey) -and -not(Test-Path $caCrt)) {
        Write-Host "--> Found: SSL Certificate"
    }

    if((Test-Path $tlsCrt) -and (Test-Path $tlsKey) -and (Test-Path $caCrt) -and -not(Test-Path $caKey)) {
        Write-Host "--> Found: SSL + CA Certificate"
    }
    $namespace = $environment.Variables['CLUEDIN_NAMESPACE']
    $commandOutput = InvokeCommand $kubectl.Command @('get', 'secret', '--kubeconfig', $environment.KubeConfig, '-n', $namespace, "-o=jsonpath='{.items[*].metadata.name}'")


    $dockerSecretName = $environment.Variables['CLUSTER_DOCKER_SECRET_NAME']
    $nugetSecretName = $environment.Variables['CLUSTER_NUGET_SECRET_NAME']
    $dockerSecret = $commandOutput | Select-String -Pattern $dockerSecretName -SimpleMatch -Raw
    $nugetSecret  = $commandOutput | Select-String -Pattern $nugetSecretName -SimpleMatch -Raw

    if(($dockerSecret) -and ($nugetSecret) -and ($Force -eq $False)) {
        Write-Host "+----------------------------------------------------+"
        Write-Host "--> Skipping: Docker & Nuget secrets found."
        Write-Host "+----------------------------------------------------+"
        return
    }

    Push-Location (Join-Path ([Paths]::TerraformScripts) '20_credentials')
    try {

        Write-Host "Uploading credentials please wait .." -NoNewline
        $tfEnvironment = GetTerraformEnvrionment $Environment -Context credentials
        InvokeCommand $terraform.Command init -EnvironmentVariables $tfEnvironment | Write-Verbose

        Write-Host ".." -NoNewline

        InvokeCommand $terraform.Command @('apply', '-auto-approve') -EnvironmentVariables $tfEnvironment | Write-Verbose

        WriteComplete
    } finally {
        Pop-Location

    }
}

function Invoke-ClusterInstall {
    [CmdletBinding()]
    [CluedInAction(Action = 'install', Context = 'cluster', Header = 'Install CluedIn application into cluster')]
    Param(
        [string]$Env = 'default',
        [ValidateNotNullOrEmpty()]
        [ValidateSet('services','cluedin')]
        [string[]]$InstallType = @('services','cluedin'),
        [Switch]$Force = $false
    )

    SetClusterTools
    $environment = GetClusterEnvironment -Name $Env
    if(-not $environment) { return }

    if(!(Test-Path $environment.KubeConfig)) {
        Write-Host "--> Error: Kubeconfig NOT found. [$($environment.KubeConfig)]"
        Write-Host "+----------------------------------------------------+"
        return
    }

    # Check secrets are created

    $namespace = $environment.Variables['CLUEDIN_NAMESPACE']
    $commandOutput = InvokeCommand $kubectl.Command @('get', 'secret', '--kubeconfig', $Environment.KubeConfig, '-n', $namespace, "-o=jsonpath='{.items[*].metadata.name}'")

    $dockerSecretName = $environment.Variables['CLUSTER_DOCKER_SECRET_NAME']
    $nugetSecretName = $environment.Variables['CLUSTER_NUGET_SECRET_NAME']
    $dockerSecret = $commandOutput | Select-String -Pattern $dockerSecretName -SimpleMatch -Raw
    $nugetSecret  = $commandOutput | Select-String -Pattern $nugetSecretName -SimpleMatch -Raw

    if((-not $dockerSecret) -and (-not $nugetSecret) -and ($Force -eq $False)) {
        Write-Host "+----------------------------------------------------+"
        Write-Host "--> Error: No secrets. Please run `"prepare`" first."
        Write-Host "+----------------------------------------------------+"
        return
    }

    # TODO: (Optional) Collect email server details (username / password)

    if($InstallType -contains 'services') {

        # Install Infrastructure
        
        if($Force){
            $Environment.Variables['CLUEDIN_INSTALL_RECREATE_PODS'] = 'true'
        }
        
        Push-Location (Join-Path ([Paths]::TerraformScripts) '30_infrastructure')
        try {
            
            Write-Host "Creating infrastructure  .." -NoNewline

            $tfEnvironment = GetTerraformEnvrionment $Environment -Context infrastructure
            InvokeCommand $terraform.Command init -EnvironmentVariables $tfEnvironment | Write-Verbose

            Write-Host ".." -NoNewline

            #TODO/WARNING: THIS TERRAFORM USES THE CLUEDIN-DEV FEED FOR NOW !

            InvokeCommand $terraform.Command @('apply', '-auto-approve') -EnvironmentVariables $tfEnvironment -ErrorAction Stop | Write-Verbose

            Write-Host ".. Done"

        } finally {
            Pop-Location
        }
    }

    if($InstallType -contains 'cluedin') {

        # Install application

        if($Force){
            $Environment.Variables['CLUEDIN_INSTALL_RECREATE_PODS'] = 'true'
        }
        
        # Get loopback IP (needed for nip.io addresses)

        $loopbackEnabled = GetOrRequestVariable $environment 'CLUEDIN_LOOPBACK_ENABLED' -Message 'Would you like to enable to loopback address?' -BoolResponse

        if($loopbackEnabled) {
            $loopbackIP = InvokeCommand $kubectl.Command @('get', '--kubeconfig', $Environment.KubeConfig, '-n', $namespace, 'svc', 'cluedin-haproxy-ingress', '-o', "jsonpath={.spec.clusterIP}")
            InvokeEnvironment -Name $Environment.Name -Context 'cluster' -Set "CLUEDIN_LOOPBACK_IP=$loopbackIP"
            $Environment.Variables['CLUEDIN_LOOPBACK_IP'] = $loopbackIP
        }

        $kubernetesVersion = InvokeCommand $kubectl.Command @('version', '-o', 'json', '--kubeconfig', $Environment.KubeConfig) | ConvertFrom-Json

        if($null -ne $kubernetesVersion)
        {
            if ($null -ne $kubernetesVersion.serverVersion)
            {
                $Environment.Variables['KUBERNETES_VERSION'] = "v" + $kubernetesVersion.serverVersion.major + "." + $kubernetesVersion.serverVersion.minor
            }
        }

        Push-Location (Join-Path ([Paths]::TerraformScripts) "40_application")

        try {
            
            Write-Host "Installing application .." -NoNewline

            $tfEnvironment = GetTerraformEnvrionment $Environment -Context application
            InvokeCommand $terraform.Command init -EnvironmentVariables $tfEnvironment -ErrorAction Stop | Write-Verbose

            Write-Host ".." -NoNewline

            #TODO/WARNING: THIS TERRAFORM USES THE CLUEDIN-DEV FEED FOR NOW !

            InvokeCommand $terraform.Command @('apply', '-auto-approve') -EnvironmentVariables $tfEnvironment | Write-Verbose

            Write-Host ".. Done"

        } finally {
            Pop-Location
        }
    }

    WriteComplete
}

function Invoke-ClusterCreateOrg {
    [CmdletBinding()]
    [CluedInAction(Action = 'createorg', Context = 'cluster', Header = 'Create an organization')]
    Param(
        [string]$env = 'default'
    )

    SetClusterTools
    $environment = GetClusterEnvironment -Name $Env
    if(-not $environment) { return }

    if(!(Test-Path $environment.KubeConfig)) {
        Write-Host "--> Error: Kubeconfig NOT found. [$($environment.KubeConfig)]"
        Write-Host "+----------------------------------------------------+"
        return
    }

    $namespace = $environment.Variables['CLUEDIN_NAMESPACE']

    # Get ORG details

    $organizationName = GetOrRequestVariable $environment 'CLUEDIN_ORGANIZATION_NAME' -Message 'Please enter the name of the organization to create'
    $organizationEmail = GetOrRequestVariable $environment 'CLUEDIN_ORGANIZATION_EMAIL' -Message 'Please enter the email to use for the admin account'

    if(-Not ($organizationEmail -Match $script:emailRegex)) {
        Write-Host "+----------------------------------------------------+"
        Write-Host "--> Error: Admin account email address [$organizationEmail] is invalid"
        Write-Host "+----------------------------------------------------+"
        return
    }

    # TODO: CATCH NOT ALLOWED ORG NAMES

    $commandOutput = InvokeCommand $kubectl.Command @('get', 'org', "${organizationName}-organization", '--ignore-not-found', '--kubeconfig', $Environment.KubeConfig, '-n', $namespace, '-o', "jsonpath='{.status.message}'")
    
    # Create organziation

    if($commandOutput -like "*activated*")
    {
        Write-Host "Creating organization : Skipped (Already created)"
    }
    else
    {
        Push-Location (Join-Path ([Paths]::TerraformScripts) "50_createorg")

        try {
            
            Write-Host "Creating organization .." -NoNewline

            $tfEnvironment = GetTerraformEnvrionment $Environment -Context createorg
            InvokeCommand $terraform.Command init -EnvironmentVariables $tfEnvironment | Write-Verbose

            Write-Host ".." -NoNewline

            #TODO/WARNING: THIS TERRAFORM USES THE CLUEDIN-DEV FEED FOR NOW !

            InvokeCommand $terraform.Command @('apply', '-auto-approve') -EnvironmentVariables $tfEnvironment | Write-Verbose

            Write-Host ".. Done"

            Write-Host "      --> Waiting for organization to be activated.. "

        } finally {
            Pop-Location
        }
    }

    $commandOutput = InvokeCommand $kubectl.Command @('get', 'org', "${organizationName}-organization", '--kubeconfig', $Environment.KubeConfig, '-n', $namespace, '-o', "jsonpath='{.status.message}'")

    # Check organziation

    if($commandOutput -like "*activated*")
    {
        Push-Location (Join-Path ([Paths]::TerraformScripts) "50_createorg")

        try
        {
            $tfEnvironment = GetTerraformEnvrionment $Environment -Context createorg
            $organizationPassword = InvokeCommand $terraform.Command @('output', '-raw', '"cluedin_org_password"') -EnvironmentVariables $tfEnvironment

            $protocol = "http"

            $certPath = Join-Path $environment.Certs 'ca.crt'
            $tlsPath = Join-Path $environment.Certs 'tls.crt'

            if ((Test-Path $certPath) -or (Test-Path $tlsPath))
            {
                $protocol = "https"
            }

            $domain = $Environment.Variables['CLUEDIN_DOMAIN']

            Write-Host "+----------------------------------------------------+"
            Write-Host "--> [ Login Details ]"
            Write-Host "--> URL     : ${protocol}://${organizationName}.${domain}"
            Write-Host "--> Username: $organizationEmail"
            Write-Host "--> Password: $organizationPassword"
        }
        finally {
            Pop-Location
        }
    }
    else
    {
        Write-Host "      --> Organization not activated yet [$commandOutput]. Try again in a miniute."
    }

    WriteComplete
}

function Invoke-ClusterUninstall {
    [CmdletBinding()]
    [CluedInAction(Action = 'uninstall', Context = 'cluster', Header = 'UnInstall CluedIn application from cluster')]
    Param(
        [string]$env = 'default',
        [Switch]$DeleteServices = $false,
        [Switch]$DeleteNamespace = $false
    )

    SetClusterTools
    $environment = GetClusterEnvironment -Name $Env
    if(-not $environment) { return }

    if(!(Test-Path $environment.KubeConfig)) {
        Write-Host "--> Error: Kubeconfig NOT found. [$($environment.KubeConfig)]"
        Write-Host "+----------------------------------------------------+"
        return
    }

    $namespace = $Environment.Variables['CLUEDIN_NAMESPACE']

    # TODO: REMOVE ORG (BROKEN ON SERVER!)

    # Remove Application

    Push-Location (Join-Path ([Paths]::TerraformScripts) "40_application")

    try {

        Write-Host "Part #1.1 - Removing Application .." -NoNewline

        $tfEnvironment = GetTerraformEnvrionment $Environment -Context application
        InvokeCommand $terraform.Command @('destroy', '-auto-approve') -EnvironmentVariables $tfEnvironment | Write-Verbose

        Write-Host "Part #1.2 - Removing Application CRDs .." -NoNewline

        InvokeCommand $kubectl.Command @('api-resources', '-o', 'name') |
            Where-Object { $_ -like '*.api.cluedin.com' } |
            ForEach-Object { InvokeCommand $kubectl.Command @('delete', 'crd', $_) | Write-Verbose }

        Write-Host ".. Done"

    } finally {
        Pop-Location
    }

    # Remove Infrastructure

    if($DeleteServices)
    {
        Push-Location (Join-Path ([Paths]::TerraformScripts) "30_infrastructure")

        try {

            Write-Host "+----------------------------------------------------+"
            Write-Host "Part #2.1 - Removing Infrastructure .." -NoNewline

            $tfEnvironment = GetTerraformEnvrionment $Environment -Context infrastructure
            InvokeCommand $terraform.Command @('destroy', '-auto-approve') -EnvironmentVariables $tfEnvironment | Write-Verbose

            Write-Host ".. Done"

            Write-Host "Part #2.2 - Removing PVC Disks .." -NoNewline

            InvokeCommand $kubectl.Command @('delete', 'pvc', '--all', '--kubeconfig', $Environment.KubeConfig, '-n', $namespace) | Write-Verbose

            Write-Host ".. Done"

            Write-Host "Part #2.3 - Removing CRDs .." -NoNewline

            InvokeCommand $kubectl.Command @('api-resources', '-o', 'name') |
            Where-Object { $_ -like '*.monitoring.coreos.com' } |
            ForEach-Object { InvokeCommand $kubectl.Command @('delete', 'crd', $_) | Write-Verbose }

            Write-Host ".. Done"

        } finally {
            Pop-Location
        }
    } else {
        Write-Host "+----------------------------------------------------+"
        Write-Host "Part #2 - Remove Infrastructure : Skipped"
    }


    # Remove Credentials

    if($DeleteNamespace) {

        Push-Location (Join-Path ([Paths]::TerraformScripts) "20_credentials")

        try {

            Write-Host "+----------------------------------------------------+"
            Write-Host "Part #3 - Remove Secrets + Namespace .." -NoNewline

            $tfEnvironment = GetTerraformEnvrionment $Environment -Context credentials
            InvokeCommand $terraform.Command @('destroy', '-auto-approve') -EnvironmentVariables $tfEnvironment | Write-Verbose

            Write-Host ".. Done"

        } finally {
            Pop-Location

        }

    } else {
        Write-Host "+----------------------------------------------------+"
        Write-Host "Part #3 - Remove Secrets + Namespace : Skipped"
    }

    WriteComplete
}