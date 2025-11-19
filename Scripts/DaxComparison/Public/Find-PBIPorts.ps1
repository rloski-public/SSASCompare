function Find-PBIPorts {
    <#
.SYNOPSIS
    Finds the Ports associated with PBI Desktop data models

.DESCRIPTION 
    Find-PBIPorts identifies the running processes associated with the data model that
    Power BI spins up when it is running with data.  You can connect to that model 
    with various tools
.EXAMPLE
    Find-PBIPorts

.OUTPUTS
    List of ports, with additional information

.NOTES
    Author: Russ Loski
#>
    foreach($id in Get-Process -Name msmdsrv|select Id  ) {
Get-NetTCPConnection -State Listen | Where-Object { $_.OwningProcess -eq $Id.Id }
}

    }
