    function Invoke-DAXQuery {
    <#
.SYNOPSIS
    Runs a Dax query on a server.  It uses the Oledb MSOLAP provider

.DESCRIPTION 
    Invoke-DAXQuery  is a function that takes a DAX Query and connection
    information (Server and Database) and runs it.  It returns a DataTable.
    This function uses the OleDB namespace, using the MSOLAP provider.


.PARAMETER ServerName
    The SSAS server name for running the query.

.PARAMETER DatabaseName
    The SSAS database to run the query on.

.PARAMETER DAXQuery
    The DAX Query as a string.

.PARAMETER EffectiveUserName
    This is used to pass in the user information, in whose context the query is run.  This is used 
    to test Row Level Security (RLS)

.EXAMPLE
    Invoke-DAXQuery -ServerName "ProdServer" -DatabaseName "ModelDB" -DAXQuery "EVALUATE INFO.VIEW.TABLES()"`
        -EffectiveUserName "User1"


.OUTPUTS
    System.Data.DataTable 

.NOTES
    Author: Russ Loski
    This could be changed to get multiple tables using a Dataset rather than a datatable
#>
        param (
            [Parameter(Mandatory=$true)][string]$ServerName,
            [string]$DatabaseName,
            [Parameter(Mandatory=$true)][string]$DaxQuery,
            [string]$EffectiveUserName

        )

        # Create the basic connection string
        $connString = "Provider=MSOLAP;Data Source=$ServerName"


        # Add the database name if there is one
        if($DatabaseName) {
            $connString += ";Catalog=$DatabaseName"
        }

        # Add the Effective User Name if there is one
        if($EffectiveUserName) {
            $connString += ";EffectiveUserName=$EffectiveUserName"
        }
        
        # Connect to the server
        $server = New-Object System.Data.OleDb.OleDbConnection
        $server.ConnectionString = $connString
        $server.Open()

        # Get the command
        $cmd = $server.CreateCommand()
        $cmd.CommandText = $DaxQuery

        # Fill the table
        $adp = New-Object System.Data.OleDb.OleDbDataAdapter $cmd
        $tbl = New-Object System.Data.DataTable 
        $rowsLoaded = $adp.Fill($tbl)
        return , $tbl
    }
