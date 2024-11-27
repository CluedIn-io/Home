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

    $port = $envDetails.CLUEDIN_UI_LOCALPORT_HTTPS ?? $envDetails.CLUEDIN_UI_LOCALPORT ?? '9080'
    $domain = $envDetails.CLUEDIN_DOMAIN ?? '127.0.0.1.nip.io'
    $protocol = $envDetails.CLUEDIN_UI_LOCALPORT_HTTPS ? 'https' : 'http'
    $address = "${protocol}://${Org}.${domain}:${port}"
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
        [switch]$AllowEmailSignup = $false,
        # Enable single sign on, which requires the appplication id and the authentication scheme
        [switch]$EnableSingleSignOn = $false,
        [Parameter(HelpMessage='Application or Client ID from sso external provider')]
        [string]$AppId,
        [Parameter(HelpMessage="Unique scheme ID, 'AAD' for example to represent Azure Active Directory (these must be unique within the table and have no spaces or characters invalid in a URL)")]
        [AuthScheme]$AuthScheme,
        [Parameter(HelpMessage="Secret from sso external provider")]
        [string]$Secret = "SSO Application Secret",
        [Parameter(HelpMessage="External provider URL, for AAD this would be https://login.microsoftonline.com/common")]
        [string]$AuthorityUrl = "https://login.microsoftonline.com/common"
    )
    
    enum AuthScheme {
        AzureAD
    }

    $serverPort  = GetEnvironmentValue -Name $Env -Key 'CLUEDIN_SERVER_AUTH_LOCALPORT' -DefaultValue '9001'
    $domain = GetEnvironmentValue -Name $Env -Key 'CLUEDIN_DOMAIN' -DefaultValue 'localhost'
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

    $success = $true
    try {

        if ($EnableSingleSignOn) {
            $uiHttpsPort  = GetEnvironmentValue -Name $Env -Key 'CLUEDIN_UI_LOCALPORT_HTTPS' -DefaultValue '443'

            $auths = ''
            $authid = ''
            if ($AuthScheme -eq [AuthScheme]::AzureAD) {
                $auths = 'aad'
                $authid = '54118954-951F-41A9-B0A7-6DE7D47E6C17'
            }

            if (-not $AppId -or -not $auths) {
                throw "The AppId and AuthScheme is mandatory when EnableSingleSignOn."
            }
            # generate token
            $requestArgs = @{
                Method = 'POST'
                Uri = "http://${domain}:${serverPort}/connect/token"
                Headers = @{
                    'Content-Type' = 'application/x-www-form-urlencoded'
                    'cache-control' = 'no-cache'
                }
                Body = @{
                    'grant_type' = 'password'
                    'username' = $Email
                    'password' = $Pass
                    'client_id' = $Name

                }
                UseBasicParsing = $true
            }
            $tokenResult = Invoke-RestMethod @requestArgs
            $token = $tokenResult.access_token

            # create sso
            $body = @{
                id = [guid]::NewGuid()
                singleSignOnProviderId = $authid
                externalId = $AppId
                externalSecret = $Secret
                authenticationScheme = $auths
                authorityUrl = $AuthorityUrl
                active = $true
                loginUrl = "https://${Name}.${domain}:${uiHttpsPort}/ssocallback"
                logoutUrl = "https://${Name}.${domain}:${uiHttpsPort}/logout"
                changePasswordUrl = "https://${Name}.${domain}:${uiHttpsPort}/changepassword"
                customErrorUrl = "https://${Name}.${domain}:${uiHttpsPort}/error"
            }
            $jsonBody = $body | ConvertTo-Json

            $requestArgs = @{
                Method = 'POST'
                Uri = "http://${domain}:${serverPort}/sso"
                Headers = @{
                    'Content-Type' = 'application/json'
                    'cache-control' = 'no-cache'
                    'Authorization' = "Bearer ${token}"
                }
                Body = $jsonBody
                UseBasicParsing = $true
            }
            Invoke-RestMethod @requestArgs -StatusCodeVariable code
            $success = $code -eq 200

            $server_container = docker ps --format "{{.Names}}" | Where-Object { ($_ -like '*-server-1') -and ($_ -like "*$Env*") }

            if ($server_container) {
                Write-Host "Restarting server to enable sso..."

                docker restart $server_container

                $d = Get-Date

                do {
                    $status = docker inspect --format "{{json .State.Health }}" $server_container | ConvertFrom-Json | Select-Object -ExpandProperty Status

                    Start-Sleep 1
                } while ($status -ne 'healthy' -and (Get-Date).Subtract($d).TotalSeconds -lt 60)
            }
            else {
                Write-Warning "Unable to determine server container. You may need to manually restart the server to enable single sign on"
            }
        }
    } catch {
        $success = $false
        Write-Host "Setup SSO was not successful"
        Write-Host $_
    } finally {
        if($EnableSingleSignOn) {
            if ($success) {
                Write-Host "SSO created for ${Name}"
            } else {
                Write-Host "SSO creation failed for ${Name}"
            }
        }
    }

}