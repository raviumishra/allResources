Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module Azure -Confirm:$False
Import-Module Azure

$appsecret = 'rkULdSvegHmypJv0hc6HDLy4hhAn3XgU+qQCvGukPM4='
$applicationId = '272de8a0-d263-4a98-a79f-ca58dcdef45c'
$tenantId = 'e525031f-bb1f-4659-aa0e-c0f3fbfa832f'

$secpasswd = ConvertTo-SecureString $appsecret -AsPlainText -Force
($creds = New-Object System.Management.Automation.PSCredential ($applicationId, $secpasswd))
Connect-AzureRmAccount -ServicePrincipal -Credential $creds -TenantId $tenantId

Start-AzureRmAutomationRunbook -Name vnetDNS_runbook -ResourceGroupName GAV-EMS-DEV-TEN-SCU-02 -AutomationAccountName GAV-EMS-DEV-TEN-SCU-04
