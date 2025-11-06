function Compare-DAXQuery {
<#
.SYNOPSIS
    Runs the same DAX query on multiple servers and compares the results

.DESCRIPTION 
    Compare-DAXQuery is a function that takes either a DAX Query or a filename  
    for a file that contains the DAX Query. It looks for a JSON structure in the 
    DAX Query comments to identify sections of the query. It runs the query on 
    both source and test SSAS servers and compares the results.

.PARAMETER FileName
    Path to the file containing the DAX Query.

.PARAMETER DAXQuery
    The DAX Query as a string. If not provided, it will be read from FileName.

.PARAMETER SourceServer
    The SSAS server with the golden model.

.PARAMETER SourceDatabase
    The SSAS database on the source server.

.PARAMETER SourceTableName
    Optional name for the source result table.

.PARAMETER TestServer
    The SSAS server to compare against the source.

.PARAMETER TestDatabase
    Optional name for the test database. Defaults to SourceDatabase.

.PARAMETER TestTableName
    Optional name for the test result table.

.PARAMETER DetailedCount
    Limits the number of differing rows returned.

.EXAMPLE
    Compare-DAXQuery -FileName "query.dax" -SourceServer "ProdServer" -SourceDatabase "ModelDB" -TestServer "DevServer"

.INPUTS
    String

.OUTPUTS
    PSCustomObject

.NOTES
    Author: Russ Loski
#>
    [CmdletBinding()]
    param (
        [string]$FileName,
        [string]$DAXQuery,
        [Parameter(Mandatory=$true)][string]$SourceServer,
        [string]$SourceDatabase,
        [string]$SourceTableName,
        [string]$TestServer,
        [string]$TestDatabase,
        [string]$TestTableName,
        [int]$DetailedCount = 10
    )



    # Set the defaults for the test server if the values are not given

    if (-not $TestServer)
    {
       $TestServer = $SourceServer 
    }

    if (-not $TestDatabase)
    {
       $TestDatabase = $SourceDatabase 
    }

    
    # Verify that there is a difference between the source and test

    if ($TestServer -eq $SourceServer -and $TestDatabase -eq $SourceDatabase)
    {
        throw "The source connection and test connections need to differ in some way."

    }
    # Load DAX query from file if not provided
    if (-not $DAXQuery -and $FileName) {
        if (-not (Test-Path $FileName)) {
            throw "File not found: $FileName"
        }
        $DAXQuery = Get-Content -Path $FileName -Raw
    }

    if (-not $DAXQuery) {
        throw "DAXQuery or FileName must be provided."
    }

    # Get the metadata from the query

    try {
        $queryMetadataFile = Get-DAXQueryMetaData -DaxQuery $DAXQuery
        if ($queryMetadataFile -and $queryMetadataFile.QueryMetaData -and $queryMetadataFile.QueryMetaData.FilterSets){
        $queryMetadata =  $queryMetadataFile.QueryMetaData.FilterSets
        }
        else
        {
            Write-Error "There is not metadata in this file"
            return
        }

    } catch {
        Write-Error "Unable to read metadata"
        return
    }


    # Default table names
    if (-not $SourceTableName) {
        $SourceTableName = "$($SourceServer)_$($SourceDatabase)" 
    }

    if (-not $TestTableName) {
        $TestTableName = "$($TestServer)_$($TestDatabase)"
    }

    # Cleanup the table names
     $SourceTableName = $SourceTableName -replace '[^a-zA-Z0-9]', '_'
     $TestTableName = $TestTableName -replace '[^a-zA-Z0-9]', '_'

    # Make certain that the table name is different
    if ($SourceTableName -eq $TestTableName) {
        $TestTableName = $TestTableName + "_TEST"
    }

    # Initialize the dataset to hold all of the tables and relationships

    $ds = New-Object System.Data.DataSet

    # Run DAX query on both servers

    # Load the source table

    [System.Data.DataTable] $sourceResults = Invoke-DAXQuery -ServerName $SourceServer -DatabaseName $SourceDatabase -DaxQuery $DAXQuery
    $sourceResults.TableName = $SourceTableName
    $ds.Tables.Add($sourceResults)

    #Load the test table 
    [System.Data.DataTable]$testResults =  Invoke-DAXQuery -ServerName $TestServer -DatabaseName $TestDatabase -DaxQuery $DAXQuery 
    $testResults.TableName = $TestTableName
    $ds.Tables.Add($testResults)
    
    # Compare at the table level
    $TableComparison = @{}
    $TableComparison[$SourceTableName] = [PSCustomObject]@{RowCount = $ds.Tables[$SourceTableName].Rows.Count
                                        ColumnCount  = $ds.Tables[$SourceTableName].Columns.Count
                                        }
 
    $TableComparison[$TestTableName]= [PSCustomObject]@{RowCount = $ds.Tables[$TestTableName].Rows.Count
                                        ColumnCount  = $ds.Tables[$TestTableName].Columns.Count
                                        }
    
    if($ds.Tables[$TestTableName].Columns.Count -ne $ds.Tables[$SourceTableName].Columns.Count) {
        $TableComparison["ColumnError"] = "Column counts don't match"
    }
    if($ds.Tables[$TestTableName].Rows.Count -ne $ds.Tables[$SourceTableName].Rows.Count) {
        $TableComparison["RowError"] = "Row counts don't match"
    }

    # Test the key columns
    if($queryMetadata.Count -eq 0){
        if(-not $TableComparison.ContainsKey("MetaDataWarning")){
        $TableComparison["MetaDataWarning"] = @{}
        }
        $TableComparison["MetaDataWarning"]["Empty Metadata"] = "There is no metadata.  The comparisons may be uneven."

        $retValue = Compare-DAXDataTable -SourceDataTable $sourceResults -TestDataTable $testResults 
        if(-not $TableComparison.ContainsKey("CompareTables")){
            $TableComparison["CompareTables"] = @{}
        }
        $TableComparison["CompareTables"]["No Metadata"] = $retValue
    }
    else {
        for($i = 0; $i -lt $queryMetadata.Count; $i++){
            $errorColumns = @()
            foreach($column in $queryMetadata[$i].KeyColumns) {
                if(-not $ds.Tables[$SourceTableName].Columns.Contains($column)){
                    $errorColumns += "Column $column not found in $SourceTableName"
                }
                if(-not $ds.Tables[$TestTableName].Columns.Contains($column)){
                    $errorColumns += "Column $column not found in $TestTableName"
                }

            }
            # Get the name of this and set to arbitrary name if missing
            $itemname = $queryMetadata[$i].Name
            if(-not $itemname){
                $itemname = "Metadata item $i"
            }
            if($errorColumns.Count -gt 0) {
                $queryMetadata[$i]|Add-Member -MemberType NoteProperty -Name Error -Value $true -Force 

                # Create an error object if it doesn't exist
                if(-not $TableComparison.ContainsKey("MetaDataError")){
                    $TableComparison["MetaDataError"] = @{}
                }
                $errorcolumnstr = $errorColumns -join "; "
                $TableComparison["MetaDataError"][$itemname] = "Key columns not in table $errorcolumnstr"

            }
            else {
            # Compare the results
            $retValue = Compare-DAXQueryDataTable -SourceDataTable $sourceResults -TestDataTable $testResults `
                -Filter $queryMetadata[$i].Filter -KeyColumns $queryMetadata[$i].KeyColumns

            if(-not $TableComparison.ContainsKey("CompareTables")){
                $TableComparison["CompareTables"] = @{}
            }
            $TableComparison["CompareTables"][$itemname] = $retValue           
          }
        }
    }


    # Output
 
     return , [PSCustomObject]@{
        SourceServer   = $SourceServer
        SourceDatabase = $SourceDatabase
        SourceTableName = $SourceTableName
        TestServer     = $TestServer
        TestDatabase = $TestDatabase
        TestTableName = $TestTableName
        TableComparison = $TableComparison
        Metadata       = $queryMetadata

    }         
}