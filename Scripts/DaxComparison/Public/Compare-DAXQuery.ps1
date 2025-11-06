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

.PARAMETER TargetServer
    The SSAS server to compare against the source.

.PARAMETER TargetDatabase
    Optional name for the target database. Defaults to SourceDatabase.

.PARAMETER TargetTableName
    Optional name for the target result table.

.PARAMETER DetailedCount
    Limits the number of differing rows returned.

.EXAMPLE
    Compare-DAXQuery -FileName "query.dax" -SourceServer "ProdServer" -SourceDatabase "ModelDB" -TargetServer "DevServer"

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
        [string]$TargetServer,
        [string]$TargetDatabase,
        [string]$TargetTableName,
        [int]$DetailedCount = 10
    )



    # Set the defaults for the test server if the values are not given

    if (-not $TargetServer)
    {
       $TargetServer = $SourceServer 
    }

    if (-not $TargetDatabase)
    {
       $TargetDatabase = $SourceDatabase 
    }

    
    # Verify that there is a difference between the source and test

    if ($TargetServer -eq $SourceServer -and $TargetDatabase -eq $SourceDatabase)
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

    if (-not $TargetTableName) {
        $TargetTableName = "$($TargetServer)_$($TargetDatabase)"
    }

    # Cleanup the table names
     $SourceTableName = $SourceTableName -replace '[^a-zA-Z0-9]', '_'
     $TargetTableName = $TargetTableName -replace '[^a-zA-Z0-9]', '_'

    # Make certain that the table name is different
    if ($SourceTableName -eq $TargetTableName) {
        $TargetTableName = $TargetTableName + "_TEST"
    }


    # Run DAX query on both servers

    # Load the source table

    [System.Data.DataTable] $sourceDataTable = Invoke-DAXQuery -ServerName $SourceServer -DatabaseName $SourceDatabase -DaxQuery $DAXQuery
    $sourceDataTable.TableName = $SourceTableName


    #Load the test table 
    [System.Data.DataTable]$targetDataTable =  Invoke-DAXQuery -ServerName $TargetServer -DatabaseName $TargetDatabase -DaxQuery $DAXQuery 
    $targetDataTable.TableName = $TargetTableName

    
    # Compare at the table level
    $TableComparison = @{}
    $TableComparison[$SourceTableName] = [PSCustomObject]@{RowCount = $sourceDataTable.Rows.Count
                                        ColumnCount  = $sourceDataTable.Columns.Count
                                        }
 
    $TableComparison[$TargetTableName]= [PSCustomObject]@{RowCount = $targetDataTable.Rows.Count
                                        ColumnCount  = $targetDataTable.Columns.Count
                                        }
    
    if($targetDataTable.Columns.Count -ne $sourceDataTable.Columns.Count) {
        $TableComparison["ColumnError"] = "Column counts don't match"
    }
    if($targetDataTable.Rows.Count -ne $sourceDataTable.Rows.Count) {
        $TableComparison["RowError"] = "Row counts don't match"
    }

    # Test the key columns
    if($queryMetadata.Count -eq 0){
        if(-not $TableComparison.ContainsKey("MetaDataWarning")){
        $TableComparison["MetaDataWarning"] = @{}
        }
        $TableComparison["MetaDataWarning"]["Empty Metadata"] = "There is no metadata.  The comparisons may be uneven."

        $retValue = Compare-DAXDataTable -SourceDataTable $sourceDataTable -TargetDataTable $targetDataTable 
        if(-not $TableComparison.ContainsKey("CompareTables")){
            $TableComparison["CompareTables"] = @{}
        }
        $TableComparison["CompareTables"]["No Metadata"] = $retValue
    }
    else {
        for($i = 0; $i -lt $queryMetadata.Count; $i++){
            $errorColumns = @()
            foreach($column in $queryMetadata[$i].KeyColumns) {
                if(-not $sourceDataTable.Columns.Contains($column)){
                    $errorColumns += "Column $column not found in $SourceTableName"
                }
                if(-not $targetDataTable.Columns.Contains($column)){
                    $errorColumns += "Column $column not found in $TargetTableName"
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
            $retValue = Compare-DAXQueryDataTable -SourceDataTable $sourceDataTable -TargetDataTable $targetDataTable `
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
        TargetServer     = $TargetServer
        TargetDatabase = $TargetDatabase
        TargetTableName = $TargetTableName
        TableComparison = $TableComparison
        Metadata       = $queryMetadata

    }         
}