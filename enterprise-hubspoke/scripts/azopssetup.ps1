### PowerShell script to bootstrap AzOps - as part of Hub-Spoke landing zone setup

[CmdletBinding()]
param (
 [string]$KeyVault,
 [string]$GitHubUserNameOrOrg,
 [string]$PATSecretName,
 [string]$SPNSecretName,
 [string]$SpnAppId,
 [string]$AzureTenantId,
 [string]$AzureSubscriptionId,
 [string]$EnterpriseScalePrefix,
 [string]$NewRepositoryName
)

$DeploymentScriptOutputs = @{}

$ESLZGitHubOrg = "Azure"
$ESLZRepository = "AzOps-Accelerator"
$NewESLZRepository = $NewRepositoryName
$DeploymentScriptOutputs['New Repository'] = $NewRepositoryName

Write-Host "The request has been accepted for processing, but the processing has not been completed."

# Adding sleep so that RBAC can propegate
Start-Sleep -Seconds 500

$ErrorActionPreference = "Continue"
Install-Module -Name PowerShellForGitHub,PSSodium -Confirm:$false -Force
Import-Module -Name PowerShellForGitHub,PSSodium
Set-GitHubConfiguration -DisableTelemetry

Try {
    Write-Host "Getting secrets from KeyVault"

    Write-Host "Getting $($PATSecretName)"

    $PATSecret = Get-AzKeyVaultSecret -VaultName $KeyVault -Name $PATSecretName -AsPlainText

    Write-Host "Converting $($PATSecretName)"
    $SecureString = $PATSecret | ConvertTo-SecureString -AsPlainText -Force
    $Cred = New-Object System.Management.Automation.PSCredential "ignore", $SecureString
}
Catch {
    $ErrorMessage = "Failed to retrieve the secret from $($KeyVault)."
    $ErrorMessage += " `n"
    $ErrorMessage += 'Error: '
    $ErrorMessage += $_
    Write-Error -Message $ErrorMessage `
                -ErrorAction Stop
}
Try {
    Write-Host "Getting $($SPNSecretName)"

    $SPNSecret = Get-AzKeyVaultSecret -VaultName $KeyVault -Name $SPNSecretName -AsPlainText
}
Catch {
    $ErrorMessage = "Failed to retrieve the secret from $($KeyVault)."
    $ErrorMessage += " `n"
    $ErrorMessage += 'Error: '
    $ErrorMessage += $_
    Write-Error -Message $ErrorMessage `
                -ErrorAction Stop
}
Try {
    Write-Host "Authenticating to GitHub using PA token..."

    Set-GitHubAuthentication -Credential $Cred
}
Catch {
    $ErrorMessage = "Failed to authenticate to Git. Ensure you provided the correct PA Token for $($GitHubUserNameOrOrg)."
    $ErrorMessage += " `n"
    $ErrorMessage += 'Error: '
    $ErrorMessage += $_
    Write-Error -Message $ErrorMessage `
                -ErrorAction Stop
}
Try {
    Write-Host "Creating Git repository from template..."
    Write-Host "Checking if repository already exists..."
    # Creating GitHub repository based on Enterprise-Scale
    $CheckIfRepoExists = @{
        Uri     = "https://api.github.com/repos/$($GitHubUserNameOrOrg)/$($NewESLZRepository)"
        Headers = @{
            Authorization = "Token $($PATSecret)"
            "Content-Type" = "application/json"
            Accept = "application/vnd.github.v3+json"
        }
        Method = "GET"
    }
    $CheckExistence = Invoke-RestMethod @CheckIfRepoExists -ErrorAction Continue
}
Catch {
    Write-Host "Repository doesn't exist, hence throwing a $($_.Exception.Response.StatusCode.Value__)"
}
if ([string]::IsNullOrEmpty($CheckExistence)){
Try{
    Write-Host "Moving on; creating the repository :-)"

    Get-GitHubRepository -OwnerName $ESLZGitHubOrg `
                     -RepositoryName $ESLZRepository | New-GitHubRepositoryFromTemplate `
                     -TargetRepositoryName $NewESLZRepository `
                     -TargetOwnerName $GitHubUserNameOrOrg `
                     -Private
}
Catch {
    $ErrorMessage = "Failed to create Git repository for $($GitHubUserNameOrOrg)."
    $ErrorMessage += " `n"
    $ErrorMessage += 'Error: '
    $ErrorMessage += $_
    Write-Error -Message $ErrorMessage `
                -ErrorAction Stop
}
# Creating secrets for the Service Principal into GitHub
Try {
    Write-host "Getting GitHub Public Key to create new secrets..."
    
    $GetPublicKey = @{
        Uri     = "https://api.github.com/repos/$($GitHubUserNameOrOrg)/$($NewESLZRepository)/actions/secrets/public-key"
        Headers = @{
            Authorization = "Token $($PATSecret)"
        }
        Method = "GET"
    }
    $GitHubPublicKey = Invoke-RestMethod @GetPublicKey
    }
Catch {
    $ErrorMessage = "Failed to retrieve Public Key for $($GitHubUserNameOrOrg)."
    $ErrorMessage += " `n"
    $ErrorMessage += 'Error: '
    $ErrorMessage += $_
    Write-Error -Message $ErrorMessage `
                -ErrorAction Stop
}
#Convert secrets to sodium with public key
$ARMClient = ConvertTo-SodiumEncryptedString -Text $SpnAppId -PublicKey $GitHubPublicKey.key
$ARMClientSecret = ConvertTo-SodiumEncryptedString -Text $SPNSecret -PublicKey $GitHubPublicKey.key
$ARMTenant = ConvertTo-SodiumEncryptedString -Text $AzureTenantId -PublicKey $GitHubPublicKey.key
$ARMSubscription = ConvertTo-SodiumEncryptedString -Text $AzureSubscriptionId -PublicKey $GitHubPublicKey.key

Try {
$ARMClientIdBody = @"
{
"encrypted_value": "$($ARMClient)",
"key_id": "$($GitHubPublicKey.Key_id)"
}
"@

    Write-Host "Creating secret for ARMClient"

    $CreateARMClientId = @{
        Uri     = "https://api.github.com/repos/$($GitHubUserNameOrOrg)/$($NewESLZRepository)/actions/secrets/ARM_CLIENT_ID"
        Headers = @{
            Authorization = "Token $($PATSecret)"
            "Content-Type" = "application/json"
            Accept = "application/vnd.github.v3+json"
        }
        Body = $ARMClientIdBody
        Method = "PUT"
    }
    Invoke-RestMethod @CreateARMClientId
}
Catch {
    $ErrorMessage = "Failed to create secret for $($GitHubUserNameOrOrg)."
    $ErrorMessage += " `n"
    $ErrorMessage += 'Error: '
    $ErrorMessage += $_
    Write-Error -Message $ErrorMessage `
                -ErrorAction Stop
}
Try {
$ARMClientSecretBody = @"
{
"encrypted_value": "$($ARMClientSecret)",
"key_id": "$($GitHubPublicKey.Key_id)"
}
"@

    Write-Host "Creating secret for ARM Service Principal"

    $CreateARMClientSecret = @{
        Uri     = "https://api.github.com/repos/$($GitHubUserNameOrOrg)/$($NewESLZRepository)/actions/secrets/ARM_CLIENT_SECRET"
        Headers = @{
            Authorization = "Token $($PATSecret)"
            "Content-Type" = "application/json"
            Accept = "application/vnd.github.v3+json"
        }
        Body = $ARMClientSecretBody
        Method = "PUT"
    }
    Invoke-RestMethod @CreateARMClientSecret
}
Catch {
    $ErrorMessage = "Failed to create secret for $($GitHubUserNameOrOrg)."
    $ErrorMessage += " `n"
    $ErrorMessage += 'Error: '
    $ErrorMessage += $_
    Write-Error -Message $ErrorMessage `
                -ErrorAction Stop
}
Try {
$ARMTenantBody = @"
{
"encrypted_value": "$($ARMTenant)",
"key_id": "$($GitHubPublicKey.Key_id)"
}
"@

    Write-Host "Creating secret for ARM tenant id"

    $CreateARMTenant = @{
        Uri     = "https://api.github.com/repos/$($GitHubUserNameOrOrg)/$($NewESLZRepository)/actions/secrets/ARM_TENANT_ID"
        Headers = @{
            Authorization = "Token $($PATSecret)"
            "Content-Type" = "application/json"
            Accept = "application/vnd.github.v3+json"
        }
        Body = $ARMTenantBody
        Method = "PUT"
    }
    Invoke-RestMethod @CreateARMTenant
}
Catch {
    $ErrorMessage = "Failed to create Secret for $($GitHubUserNameOrOrg)."
    $ErrorMessage += " `n"
    $ErrorMessage += 'Error: '
    $ErrorMessage += $_
    Write-Error -Message $ErrorMessage `
                -ErrorAction Stop
}
Try {
$ARMSubscriptionBody = @"
{
"encrypted_value": "$($ARMSubscription)",
"key_id": "$($GitHubPublicKey.Key_id)"
}
"@

    Write-Host "Creating secret for ARM subscription id"

    $CreateARMSubscription = @{
        Uri     = "https://api.github.com/repos/$($GitHubUserNameOrOrg)/$($NewESLZRepository)/actions/secrets/ARM_SUBSCRIPTION_ID"
        Headers = @{
            Authorization = "Token $($PATSecret)"
            "Content-Type" = "application/json"
            Accept = "application/vnd.github.v3+json"
        }
        Body = $ARMSubscriptionBody
        Method = "PUT"
    }
    Invoke-RestMethod @CreateARMSubscription
}
Catch {
    $ErrorMessage = "Failed to create Git repository for $($GitHubUserNameOrOrg)."
    $ErrorMessage += " `n"
    $ErrorMessage += 'Error: '
    $ErrorMessage += $_
    Write-Error -Message $ErrorMessage `
                -ErrorAction Stop
    }
Try {
$DispatchBody = @"
{
    "event_type": "Enterprise-Scale Deployment"
}
"@
    
    Write-Host "Invoking GitHub Action to bootstrap the repository."

    $InvokeGitHubAction = @{
        Uri   = "https://api.github.com/repos/$($GitHubUserNameOrOrg)/$($NewESLZRepository)/dispatches"
        Headers = @{
            Authorization = "Token $($PATSecret)"
            Accept  = "application/vnd.github.v3+json"
        }
        Body = $DispatchBody
        Method = "POST"
    }
    Invoke-RestMethod @InvokeGitHubAction
    
    Write-Host "The end"

}
Catch {
    $ErrorMessage = "Failed to invoke GitHub Action for $($GitHubUserNameOrOrg)."
    $ErrorMessage += " `n"
    $ErrorMessage += 'Error: '
    $ErrorMessage += $_
    Write-Error -Message $ErrorMessage `
                -ErrorAction Stop
    }
}
{
    Write-Host "Repo already exists, so we will assume you are good already :-)"
    
    Write-Host "The end"
}

