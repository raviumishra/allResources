Param (
[Parameter()]
[String]$appsecret = 'rkULdSvegHmypJv0hc6HDLy4hhAn3XgU+qQCvGukPM4=',
[String]$applicationId = '272de8a0-d263-4a98-a79f-ca58dcdef45c',
[String]$tenantId = 'e525031f-bb1f-4659-aa0e-c0f3fbfa832f',
[String]$automationAccountResourceGroup = 'GAV-EMS-DEV-TEN-SCU-02',
[String]$automationAccount = 'GAV-EMS-DEV-TEN-SCU-04'
)
#DISABLE WINDOWS DEFENDER
Set-MpPreference -DisableRealtimeMonitoring $true

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module Azure -Confirm:$False
Import-Module Azure

$secpasswd = ConvertTo-SecureString $appsecret -AsPlainText -Force
($creds = New-Object System.Management.Automation.PSCredential ($applicationId, $secpasswd))
Connect-AzureRmAccount -ServicePrincipal -Credential $creds -TenantId $tenantId

Start-AzureRmAutomationRunbook -Name vnetDNS_runbook -ResourceGroupName $automationAccountResourceGroup  -AutomationAccountName $automationAccount 
