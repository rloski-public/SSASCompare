function Compare-DAXQueryDataTable {
    <#
.SYNOPSIS
    Compare two DataTables, using the filter and the 

.DESCRIPTION 
    Compare-DAXDataTable is a function that compares two DataTables.  The tables may be
    filtered and may be joined by a list of columns


.PARAMETER SourceDataTable
    The main datatable, against which the tables are compared

.PARAMETER TestDataTable
    The datatable that is being compared to the SourceDataTable

.PARAMETER Filter
    This is the filter that is applied to the datatables.  This may be null

.PARAMETER KeyColumns
    This is the list of columns that are used to join the datatables together

.EXAMPLE
    Compare-DAXQueryDataTable -SourceDataTable $tbl1 -TestDataTable $tbl2 -Filter "Col = 'val'" -KeyColumns @("Col1")


.OUTPUTS
    System.Data.DataTable 

.NOTES
    Author: Russ Loski
#>
        param (
            [Parameter(Mandatory=$true)][System.Data.DataTable]$SourceDataTable,
            [Parameter(Mandatory=$true)][System.Data.DataTable]$TestDataTable,
            [string]$Filter,
            [string[]]$KeyColumns
        )
        $ds = New-Object System.Data.DataSet
        $SourceTableName = $SourceDataTable.TableName
        $TestTableName = $TestDataTable.TableName

        $rowErrors = @{
            RowErrorCount = 0
            SourceRowColumnErrors = @{} # These are the errors when comparing columns
            SourceRowError = @{}        # These list the rows that have a mismatch of rows (missing/duplicates)
            TestRowError = @{}          # It is possible that there is a row in test that isn't in source
            }



        # Filter the tables and add to new $ds
        # This involves creating a view that is filtered then adding the table
        # I might be able to create primary keys using the array of columns
        # I used for the relations.
        if($Filter){
           $vws = New-Object System.Data.DataView($SourceDataTable,$Filter,$null, [ System.Data.DataViewRowState ]::CurrentRows)
           $vwt = New-Object System.Data.DataView($TestDataTable,$Filter,$null, [ System.Data.DataViewRowState ]::CurrentRows)
           $ds.Tables.Add($vws.ToTable($SourceTableName))
           $ds.Tables.Add($vwt.ToTable($TestTableName))
        } else
        {
            # if there are no filters, then just add the tables to the new datset
            $ds.Tables.Add($SourceDataTable)
            $ds.Tables.Add($TestDataTable)
        }

        if($KeyColumns) {
        # Build the relations:  source to test, then test to source
        # test to source is used only if the equivilent source to test does not have
        # a match

        
            $parentcols = @()
            $childcols = @()

            # Get parallel columns from the source table and the test table
            foreach ($colitem in $KeyColumns){
              $parentcols += $ds.Tables[$SourceTableName].Columns[$colitem]
              $childcols += $ds.Tables[$TestTableName].Columns[$colitem]
            }
            # Create primary keys

            # These are the re
            $rel = New-Object System.Data.DataRelation "DSComparison_SourceTest", $parentcols, $childcols
            $ds.Relations.Add($rel)    
            $rel = New-Object System.Data.DataRelation "DSComparison_TestSource", $childcols, $parentcols
            $ds.Relations.Add($rel)

            # Counters for the status of records found
            $testMatches = 0
            $sourceMatches = 0
            $duplicateTestMatches = 0
            $duplicateSourceMatches = 0
            $missingTestMatches = 0
            $missingSourceMatches = 0

            $sourceRel = $ds.Relations["DSComparison_SourceTest"]
            $testRel = $ds.Relations["DSComparison_TestSource"]


            # Walk through each of the rows in the source


            for($i = 0; $i -lt $ds.Tables[$SourceTableName].Rows.Count;$i++){
                $rowColumnErrors = @() # This is where each row error goes
                $row = $ds.Tables[$SourceTableName].Rows[$i]
                $childRows = $row.GetChildRows($sourceRel)



                # Create key for the row
                $keyvalues = ""
                foreach($keycol in $sourceRel.ParentColumns) {
                    $keycolname = $keycol.ColumnName
                    $keyvalue = $row[$keycolname]
                    $keyvalues += "$keycolname : $keyvalue ;"
                    }

                if($childRows.Count -lt 1) 
                    {$missingTestMatches+=1
                    $rowErrors["RowErrorCount"] +=1
                    $rowErrors["SourceRowError"][$keyvalues] = "Error:  Missing Test Child"
                    }
                elseif($childRows.Count -gt 1) 
                    {$duplicateTestMatches+=1
                    $rowErrors["RowErrorCount"] +=1
                    $rowErrors["SourceRowError"][$keyvalues] = "Error:  Duplicate Test Child"
                    }
                else  {$testMatches +=1
                 foreach($column in $ds.Tables[$SourceTableName].Columns) {
                    $columnName = $column.ColumnName
                    $parentvalue = $row[$columnName]
                    $childvalue = $childRows[0][$columnName] 
                    if($parentvalue -ne $childvalue) {
                        $rowErrors["RowErrorCount"] +=1
                        $rowColumnErrors += "Mismatch on column $columnName :  Source $parentValue; Test:  $childvalue"
                        }                    
                    }
                    if($rowColumnErrors.Count -gt 0){
                        $rowErrors["SourceRowColumnErrors"][$keyvalues] = $rowColumnErrors
                    }
                }



            }
            for($i = 0; $i -lt $ds.Tables[$TestTableName].Rows.Count;$i++){
                $row = $ds.Tables[$TestTableName].Rows[$i]
                $childRows = $row.GetChildRows("DSComparison_TestSource")
                 # Create key for the row
                $keyvalues = ""
                foreach($keycol in $testRel.ParentColumns) {
                    $keycolname = $keycol.ColumnName
                    $keyvalue = $row[$keycolname]
                    $keyvalues += "$keycolname : $keyvalue ;"
                    }
                if($childRows.Count -lt 1) 
                    {$missingSourceMatches+=1
                    $rowErrors["RowErrorCount"] +=1
                    $rowErrors["TestRowError"][$keyvalues] = "Error:  Missing Source Child" 
                    }
                elseif($childRows.Count -gt 1) 
                    {$duplicateSourceMatches+=1
                    $rowErrors["RowErrorCount"] +=1
                    $rowErrors["TestRowError"][$keyvalues] = "Error:  Duplicate Source Child" 
                    }

                else  {$SourceMatches +=1}
                

            }


        }
        else {
            # This will involve comparing rows in order.  If there is one value, the results
            # are good.  If there are more, then I won't trust the results as much

        }


        $ret =[PSCustomObject]@{
            Filter = $Filter
            KeyColumns = $KeyColumns
            SourceRowCount = $ds.Tables[$SourceTableName].Rows.Count
            SourceTestMatches = $testMatches
            SourceTestDuplicates = $duplicateTestMatches
            SourceTestMissing = $missingTestMatches
            TestRowCount = $ds.Tables[$TestTableName].Rows.Count
            TestSourceMatches = $sourceMatches
            TestSourceDuplicates = $duplicateSourceMatches
            TestSourceMissing = $missingSourceMatches
            RowErrors = $rowErrors 
        }

        return , $ret 

    }