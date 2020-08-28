function Invoke-CreateOrg {
    [CluedInAction(Action = 'createorg', Header = 'Create Organization')]
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [String]$Env = 'default',
        [Parameter(Mandatory)]
        [string]$Name,
        [ValidatePattern("^[a-zA-Z0-9.!#$%&*+\/=?^_{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$")]
        [string]$Email = "admin@${Name}.com",
        [string]$Pass = "P@ssword!123"
    )

    $serverPort  = GetEnvironmentValue -Name $Env -Key 'CLUEDIN_SERVER_AUTH_LOCALPORT' -DefaultValue '9001'

    $requestArgs = @{
        Method = 'POST'
        Uri = "http://localhost:${serverPort}/api/account/new"
        Headers = @{
            'Content-Type' = 'application/x-www-form-urlencoded'
            'cache-control' = 'no-cache'
        }
        Body = @{
            grant_type = 'password'
            allowEmailDomainSignup = 'false'
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
        if($_.ErrorDetails.Message) {
            ($_.ErrorDetails.Message | ConvertFrom-Json).password.'$values'
        }
    } finally {
        If($success) {
            Write-Host "Email: ${Email}"
            Write-Host "Password: ${Pass}"
        }
    }
}