Param(
[string]$applicationId,
[string][ValidateNotNullOrEmpty()]$secureStringPwd,
[string]$virtualNetworkResourceGroup,
[string]$virtualnetworkname,
[string]$pdc_networkInterfaceIP
)

#LOGON TO AZURE
$secpasswd = ConvertTo-SecureString $secureStringPwd -AsPlainText -Force
($creds = New-Object System.Management.Automation.PSCredential ($applicationId, $secpasswd))
Connect-AzureRmAccount -ServicePrincipal -Credential $credential -TenantId "f91f6220-c049-488e-a0a1-9618ddb7adc5"

#SET DNS SERVER IP IN AZURE VNET
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $virtualNetworkResourceGroup -name $virtualnetworkname 
$vnet.DhcpOptions.DnsServers = $pdc_networkInterfaceIP 
Set-AzureRmVirtualNetwork -VirtualNetwork $vnet
