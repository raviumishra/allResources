Param (
[Parameter()]
[String]$appsecret,
[String]$applicationId,
[String]$tenantId,
[String]$automationAccountResourceGroup,
[String]$automationAccount
)
#DISABLE WINDOWS DEFENDER
Set-MpPreference -DisableRealtimeMonitoring $true

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module -Name AzureRM -RequiredVersion 6.9.0 -Confirm:$False
Import-Module AzureRM

$secpasswd = ConvertTo-SecureString $appsecret -AsPlainText -Force
($creds = New-Object System.Management.Automation.PSCredential ($applicationId, $secpasswd))
Connect-AzureRmAccount -ServicePrincipal -Credential $creds -TenantId $tenantId

Start-AzureRmAutomationRunbook -Name vnetDNS_runbook -ResourceGroupName $automationAccountResourceGroup  -AutomationAccountName $automationAccount
Start-Sleep 60
Restart-Computer -Force
