Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module Azure -Confirm:$False
Import-Module Azure
Start-AzureRmAutomationRunbook -Name vnetDNS_runbook -ResourceGroupName GAV-EMS-DEV-TEN-SCU-02 -AutomationAccountName GAV-EMS-DEV-TEN-SCU-04
