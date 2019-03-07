configuration SQLServerPrepareDsc
{
    param
    (
        [Parameter(Mandatory)]
        [String]$DomainName,

		[String]$DomainNetbiosName=(Get-NetBIOSName -DomainName $DomainName),

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds

        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    )

    Import-DscResource -ModuleName xComputerManagement, xNetworking, xActiveDirectory, xStorage, SqlServer, SqlServerDsc
    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($Admincreds.UserName)", $Admincreds.Password)

    $computerName = $env:COMPUTERNAME
    $domainUserName = $DomainCreds.UserName.ToString()

    Node localhost
    {
        
		xFirewall DatabaseEngineFirewallRule
        {
            Direction = "Inbound"
            Name = "SQL-Server-Database-Engine-TCP-In"
            DisplayName = "SQL Server Database Engine (TCP-In)"
            Description = "Inbound rule for SQL Server to allow TCP traffic for the Database Engine."
            Group = "SQL Server"
            Enabled = "True"
            Protocol = "TCP"
            LocalPort = "1433"
            Ensure = "Present"
        }

        xFirewall DatabaseMirroringFirewallRule
        {
            Direction = "Inbound"
            Name = "SQL-Server-Database-Mirroring-TCP-In"
            DisplayName = "SQL Server Database Mirroring (TCP-In)"
            Description = "Inbound rule for SQL Server to allow TCP traffic for the Database Mirroring."
            Group = "SQL Server"
            Enabled = "True"
            Protocol = "TCP"
            LocalPort = "5022"
            Ensure = "Present"
        }

        xFirewall ListenerFirewallRule
        {
            Direction = "Inbound"
            Name = "SQL-Server-Availability-Group-Listener-TCP-In"
            DisplayName = "SQL Server Availability Group Listener (TCP-In)"
            Description = "Inbound rule for SQL Server to allow TCP traffic for the Availability Group listener."
            Group = "SQL Server"
            Enabled = "True"
            Protocol = "TCP"
            LocalPort = "59999"
            Ensure = "Present"
        }

        WindowsFeature FC
        {
            Name = "Failover-Clustering"
            Ensure = "Present"
        }

        WindowsFeature FailoverClusterTools 
        { 
            Ensure = "Present" 
            Name = "RSAT-Clustering-Mgmt"
            DependsOn = "[WindowsFeature]FC"
        } 

        WindowsFeature FCPS
        {
            Name = "RSAT-Clustering-PowerShell"
            Ensure = "Present"
            DependsOn = "[WindowsFeature]FailoverClusterTools"
        }

        WindowsFeature FCPSCMD
        {
            Ensure    = 'Present'
            Name      = 'RSAT-Clustering-CmdInterface'
            DependsOn = '[WindowsFeature]FCPS'
        }

        WindowsFeature ADPS
        {
            Name = "RSAT-AD-PowerShell"
            Ensure = "Present"
        }

        <#TODO: Add user for running SQL server.
        xADUser SvcUser
        {

        }
        #>

        SqlServerLogin AddDomainAdminAccountToSqlServer
        {
            Name = $DomainCreds.UserName
            LoginType = "WindowsUser"
			ServerName = "$env:COMPUTERNAME"
			InstanceName = "MSSQLSERVER"
        }

        SqlServerLogin AddClusterSvcAccountToSqlServer
        {
            Name = "NT SERVICE\ClusSvc"
            LoginType = "WindowsUser"
			ServerName = "$env:COMPUTERNAME"
			InstanceName = "MSSQLSERVER"
        }

        #TODO: Create a special group for "NT SERVICE\clusterSvc" and grant only 'Connect SQL', 
        #      'Alter Any Availability Group', and 'View Server State' permissions.
		SqlServerRole AddDomainAdminAccountToSysAdmin
        {
			Ensure = "Present"
            MembersToInclude = $DomainCreds.UserName,"NT SERVICE\ClusSvc"
            ServerRoleName = "sysadmin"
			ServerName = "$env:COMPUTERNAME"
			InstanceName = "MSSQLSERVER"
			DependsOn = "[SqlServerLogin]AddDomainAdminAccountToSqlServer","[SqlServerLogin]AddClusterSvcAccountToSqlServer"
        }

        #TODO: We should create a dedicated user for this.
        SqlServiceAccount SetServiceAcccount_User
        {
			ServerName = "$env:COMPUTERNAME"
			InstanceName = "MSSQLSERVER"
            ServiceType    = 'DatabaseEngine'
            ServiceAccount = $DomainCreds
            RestartService = $true
            DependsOn = "[SqlServerRole]AddDomainAdminAccountToSysAdmin"
        }


        #The SPNs seem to end up in the wrong containers (COMPUTERNAME) as opposed to Domain user
        #This is a bit of a hack to make sure it is straight. 
        # - See also: https://support.microsoft.com/en-sg/help/811889/how-to-troubleshoot-the-cannot-generate-sspi-context-error-message
        Script ResetSpns
        {
            GetScript = { 
                return @{ 'Result' = $true }
            }

            SetScript = {
                $spn = "MSSQLSvc/" + $using:computerName + "." + $using:DomainName
                
                $cmd = "setspn -D $spn $using:computerName"
                Write-Verbose $cmd
                Invoke-Expression $cmd

                $cmd = "setspn -A $spn $using:domainUsername"
                Write-Verbose $cmd
                Invoke-Expression $cmd

                $spn = "MSSQLSvc/" + $using:computerName + "." + $using:DomainName + ":1433"
                
                $cmd = "setspn -D $spn $using:computerName"
                Write-Verbose $cmd
                Invoke-Expression $cmd

                $cmd = "setspn -A $spn $using:domainUsername"
                Write-Verbose $cmd
                Invoke-Expression $cmd
            }

            TestScript = {
                $false
            }

            DependsOn = "[SqlServiceAccount]SetServiceAcccount_User"
            PsDscRunAsCredential = $DomainCreds
        }

        LocalConfigurationManager 
        {
            RebootNodeIfNeeded = $true
        }
    }
}

function Get-NetBIOSName
{ 
    [OutputType([string])]
    param(
        [string]$DomainName
    )

    if ($DomainName.Contains('.')) {
        $length=$DomainName.IndexOf('.')
        if ( $length -ge 16) {
            $length=15
        }
        return $DomainName.Substring(0,$length)
    }
    else {
        if ($DomainName.Length -gt 15) {
            return $DomainName.Substring(0,15)
        }
        else {
            return $DomainName
        }
    }
}