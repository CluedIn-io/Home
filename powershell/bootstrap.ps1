function Invoke-Open {
    <#
        .SYNOPSIS
        Opens CluedIn.

        .DESCRIPTION
        Starts CluedIn in the default browser using the environments configured
        host/port information.
    #>
    [CluedInAction(Action = 'open', Header = 'Opening Cluedin')]
    [CmdletBinding()]
    param(
        # The environment in which CluedIn will run.
        [Parameter(Position=0)]
        [String]$Env = 'default',
        # Open the sign in page for the specified organization.
        [String]$Org = 'app'
    )

    $envDetails = GetEnvironment -Name $Env
    if(!$envDetails) {
        throw "Environment ${Env} could not be found"
    }

    $port  = $envDetails.CLUEDIN_UI_LOCALPORT ?? '9080'
    $domain = $envDetails.CLUEDIN_DOMAIN ?? '127.0.0.1.nip.io'
    $address = "http://${Org}.${domain}:${port}"
    Start-Process $address
}

function Invoke-CreateOrg {
    <#
        .SYNOPSIS
        Creates a new organization in CluedIn.

        .DESCRIPTION
        When creating a new organization an organization admin account is also created.
        The associated login details are returned.

        .EXAMPLE
        __AllParameterSets

        ```powershell
        > .\cluedin.ps1 createorg -Name example

        +-------------------------------+
        | CluedIn - Create Organization |
        +-------------------------------+

        #...
        Email: admin@example.com
        Password: P@ssword!123
        ```
    #>
    [CluedInAction(Action = 'createorg', Header = 'Create Organization')]
    [CmdletBinding()]
    param(
        # The environment in which CluedIn will run.
        [Parameter(Position=0)]
        [String]$Env = 'default',
        # The name of the organization to created.
        [Parameter(Mandatory)]
        [string]$Name,
        # The email/username of the organization admin.
        [ValidatePattern("^[a-zA-Z0-9.!#$%&*+\/=?^_{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$")]
        [string]$Email = "admin@${Name}.com",
        # The password of the organization admin.
        [string]$Pass = "P@ssword!123",
        # If set to true, will allow direct email sign up for future users
        # using an email that matches the organization admins email domain.
        [switch]$AllowEmailSignup = $false
    )

    $serverPort  = GetEnvironmentValue -Name $Env -Key 'CLUEDIN_SERVER_AUTH_LOCALPORT' -DefaultValue '9001'
    $domain = $env.CLUEDIN_DOMAIN ?? 'localhost'
    $requestArgs = @{
        Method = 'POST'
        Uri = "http://${domain}:${serverPort}/api/account/new"
        Headers = @{
            'Content-Type' = 'application/x-www-form-urlencoded'
            'cache-control' = 'no-cache'
        }
        Body = @{
            grant_type = 'password'
            allowEmailDomainSignup = $AllowEmailSignup
            username = $Email
            email = $Email
            password = $Pass
            confirmpassword = $Pass
            applicationSubDomain = $Name
            organizationName =$Name
            emailDomain = ($Email -split '@')[1]

        }
        UseBasicParsing = $true
    }

    $success = $true
    try {
        Invoke-RestMethod @requestArgs
    } catch {
        $success = $false
        Write-Host "Create organization was not successful"
        $ex = $_
        if($ex.ErrorDetails.Message) {
            try {
                $json = $_.ErrorDetails.Message | ConvertFrom-Json
                $json.psobject.members.name |
                    ForEach-Object {
                        if($json.$_.psobject.members.name -contains '$values') {
                            $json.$_.'$values'
                        }
                    }
            } catch {
                Write-Host $ex.ErrorDetails.Message
            }
        }
    } finally {
        If($success) {
            Write-Host "Email: ${Email}"
            Write-Host "Password: ${Pass}"
        }
    }
}