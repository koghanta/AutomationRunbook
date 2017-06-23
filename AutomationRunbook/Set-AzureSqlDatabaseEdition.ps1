#
# Script.ps1
#
<#  
.SYNOPSIS  
    Vertically scale (up or down) an Azure SQL Database   
  
.DESCRIPTION  
    This runbook enables one to vertically scale (up or down) an Azure SQL Database using Azure Automation. 
    
    There are many scenarios in which the performance needs of a database follow a known schedule.
    Using the provided runbook, one could automatically schedule a database to a scale-up to a Premium/P1 
    database during peak hours (e.g., 7am to 6pm) and then scale-down the database to a Standard/S0 during
    non peak hours (e.g., 6pm-7am).

 .PARAMETER SqlServerName 
    Name of the Azure SQL Database server (Ex: zurichpoc) 
      
.PARAMETER DatabaseName  
    Target Azure SQL Database name (Ex: zurichpoc)

.PARAMETER Edition  
    Desired Azure SQL Database edition {Basic, Standard, Premium}
    For more information on Editions/Performance levels, please 
    see: http://msdn.microsoft.com/en-us/library/azure/dn741336.aspx

.PARAMETER PerfLevel  
    Desired performance level {Basic, S0, S1, S2, S3, P1, P2, P3} 
 
.PARAMETER Credential  
    Credentials for $SqlServerName stored as an Azure Automation credential asset  
    When using in the Azure Automation UI, please enter the name of the 
    credential asset for the "Credential" parameter
    
.EXAMPLE  
    Set-AzureSqlDatabaseEdition 
        -SqlServerName zurichpoc  
        -DatabaseName zurichpoc
        -Edition Standard
        -PerfLevel S0
        -Credential SQLCredential 
  
.NOTES  
    
#> 

workflow Set-AzureSqlDatabaseEdition
{
    param
    (
        # Name of the Azure SQL Database server (Ex: bzb98er9bp)
        [parameter(Mandatory=$true)]  
        [string] $SqlServerName = 'demodfsql',

        # Target Azure SQL Database name 
        [parameter(Mandatory=$true)]  
        [string] $DatabaseName = 'demosqldb',

        # Desired Azure SQL Database edition {Basic, Standard, Premium}
        [parameter(Mandatory=$true)]  
        [string] $Edition = 'Standard',

        # Desired performance level {Basic, S0, S1, S2, S3, P1, P2, P3}
        [parameter(Mandatory=$true)] 
        [string] $PerfLevel = 'S2',

        # Credentials for $SqlServerName stored as an Azure Automation credential asset
        # When using in the Azure Automation UI, please enter the name of the credential asset for the "Credential" parameter
        [parameter(Mandatory=$true)]  
        [string] $CredentialName = 'SQLCredential'
    
    )
    
    inlinescript
    {
        Write-Output "Begin vertical scaling script..."

        $Credential = Get-AutomationPSCredential -Name $Using:CredentialName
       
        # Establish credentials for Azure SQL Database server 
        $ServerCredential = new-object System.Management.Automation.PSCredential($Using:Credential.UserName, (($Using:Credential).GetNetworkCredential().Password | ConvertTo-SecureString -asPlainText -Force)) 
        
        # Create connection context for Azure SQL Database server
        $CTX = New-AzureSqlDatabaseServerContext -ManageUrl “https://$Using:SqlServerName.database.windows.net” -Credential $ServerCredential
        
        # Get Azure SQL Database context
        $Db = Get-AzureSqlDatabase $CTX –DatabaseName $Using:DatabaseName
        
        # Specify the specific performance level for the target $DatabaseName
        $ServiceObjective = Get-AzureSqlDatabaseServiceObjective $CTX -ServiceObjectiveName $Using:PerfLevel
        
        # Set the new edition/performance level
        Set-AzureSqlDatabase $CTX –Database $Db –ServiceObjective $ServiceObjective –Edition $Using:Edition -Force
        
        # Output final status message
        Write-Output "Scaled the performance level of $Using:DatabaseName to $Using:Edition - $Using:PerfLevel"
        Write-Output "Completed vertical scale"
    }
}