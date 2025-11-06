function Compare-DAXQueryDataTable {
    <#
.SYNOPSIS
    Compare two DataTables, using the filter and the 

.DESCRIPTION 
    Compare-DAXDataTable is a function that compares two DataTables.  The tables may be
    filtered and may be joined by a list of columns


.PARAMETER SourceDataTable
    The main datatable, against which the tables are compared

.PARAMETER TargetDataTable
    The datatable that is being compared to the SourceDataTable

.PARAMETER Filter
    This is the filter that is applied to the datatables.  This may be null

.PARAMETER KeyColumns
    This is the list of columns that are used to join the datatables together

.EXAMPLE
    Compare-DAXQueryDataTable -SourceDataTable $tbl1 -TargetDataTable $tbl2 -Filter "Col = 'val'" -KeyColumns @("Col1")


.OUTPUTS
    System.Data.DataTable 

.NOTES
    Author: Russ Loski
#>
        param (
            [Parameter(Mandatory=$true)][System.Data.DataTable]$SourceDataTable,
            [Parameter(Mandatory=$true)][System.Data.DataTable]$TargetDataTable,
            [string]$Filter,
            [string[]]$KeyColumns
        )
        # Initialize all of the return variables
        $rowErrors = @{
            RowErrorCount = 0
            SourceRowColumnErrors = @{} # These are the errors when comparing columns
            SourceRowError = @{}        # These list the rows that have a mismatch of rows (missing/duplicates)
            TargetRowError = @{}          # It is possible that there is a row in target that isn't in source
            }
        $mainErrors = @()
        
        # Counters for the status of records found
        $targetMatches = 0
        $sourceMatches = 0
        $duplicateTestMatches = 0
        $duplicateSourceMatches = 0
        $missingTargetMatches = 0
        $missingSourceMatches = 0
        $sourceRowCount = -1
        $targetRowCount = -1
        $sourceError = $false
        $targetError = $false 




        # This is a new dataset to hold the tables being tested
        # The tables may be filtered
        $ds = New-Object System.Data.DataSet


        $SourceTableName = $SourceDataTable.TableName
        $TargetTableName = $TargetDataTable.TableName
        ### TODO:  I need to handle an error where the table name is not present
        ### also. The names of the table should not be the same


        # Filter the tables and add to new $ds
        # This involves creating a view that is filtered then adding the table
        # I might be able to create primary keys using the array of columns
        # I used for the relations.
        if($Filter -and -not [string]::IsNullOrEmpty($Filter)){
            try {
                # Apply filter to the source and get the count of rows
                # [System.Data.DataTable] $tbl = $SourceDataTable.Copy()

                $vws = New-Object System.Data.DataView($SourceDataTable,$Filter,$null, [ System.Data.DataViewRowState ]::CurrentRows)
                $sourceRowCount = $vws.Count
            }
            catch {
                $mainErrors += "Error creating source view: " + $_.Exception.Message 
                $sourceError = $true

            }
            try {
               # Apply filter to the target and get the count of rows 
               # [System.Data.DataTable] $tbl = $TargetDataTable.Copy()

                $vwt = New-Object System.Data.DataView($TargetDataTable,$Filter,$null, [ System.Data.DataViewRowState ]::CurrentRows)
               $targetRowCount =  $vwt.Count 
            }
            catch {
                $mainErrors += "Error creating target view: " + $_.Exception.Message 
                $targetError = $true 
            }

            # Copy the views to the table
            try {
                if(-not $sourceError){
                    $ds.Tables.Add($vws.ToTable($SourceTableName))
                    $srcTble = $ds.Tables[$SourceTableName]
                    $srcTbleCount = $srcTble.Rows.Count

                    # Verify that the row count for view matches table
                    # This will continue even if there is no match
                    if($srcTbleCount  -ne $sourceRowCount) { 
											# I record the error, but don't prevent the comparison
                       $mainErrors += "Source table rows not match view; table:  $srcTbleCount ; view: $sourceRowCount"  
                        
                    }
                }
            }
            catch {
                $mainErrors += "Error adding source view to dataset: " + $_.Exception.Message 
                $sourceError = $true 
            }
            try {
                if(-not $targetError) {
                    $ds.Tables.Add($vwt.ToTable($TargetTableName))
                    $tgtTble = $ds.Tables[$TargetTableName]
                    $tgtTbleCount = $tgtTble.Rows.Count

                    # Verify that the row count for view matches table
                    # This will continue even if there is no match
                    if($tgtTbleCount  -ne $targetRowCount) { 
											# I continue with the comparison.
                       $mainErrors += "Target table rows not match view; table:  $tgtTbleCount ; view: $targetRowCount"  
                        
                    }
                    
                }
            }
            catch {
                $mainErrors += "Error adding target view to dataset: " + $_.Exception.Message 
                $targetError = $true 
            }

        } else
        {
            # if there are no filters, then just add the tables to the new datset
            try {
               # Add table to the dataset 
               [System.Data.DataTable]$tbl = $SourceDataTable.Copy()
               $tbl.TableName = $SourceTableName
               $cnt1 = $SourceDataTable.Rows.Count 
                $cnt2 = $tbl.Rows.Count 
                 $ds.Tables.Add($tbl)
                $sourceRowCount =   $ds.Tables[$SourceTableName]
                $mainErrors += "Adding to the new dataset  $cnt1 $cnt2  $sourceRowCount"
           }
            catch {
                $mainErrors += "Error adding source table: " + $_.Exception.Message 
                $sourceError = $true 
            }            
            try {
               # Add table to the dataset 
               $tgtTble = $ds.Tables.Add($TargetDataTable.Clone())
               $targetRowCount =  $srcTble.Count 
            }
            catch {
                $mainErrors += "Error adding target table: " + $_.Exception.Message 
                $targetError = $true 
            }            

        }


        if($KeyColumns) {
        # Build the relations:  source to test, then test to source
        # test to source is used only if the equivilent source to test does not have
        # a match


 
 			# The columns must all exist in both tables before adding relationships
            if($columnsAllExists -and  $targetRowCount -gt  0 -and $sourceRowCount -gt 0 -and -not $sourceError -and -not $targetError) {
                $parentcols = @()
                $childcols = @()

                # Get parallel columns from the source table and the test table
                foreach ($colitem in $KeyColumns){
                  $parentcols += $ds.Tables[$SourceTableName].Columns[$colitem]
                  $childcols += $ds.Tables[$TargetTableName].Columns[$colitem]
                }
                # Create primary keys

                # These are the re
                $rel = New-Object System.Data.DataRelation "DSComparison_SourceTest", $parentcols, $childcols
                $ds.Relations.Add($rel)    
                $rel = New-Object System.Data.DataRelation "DSComparison_TestSource", $childcols, $parentcols
                $ds.Relations.Add($rel)


                $sourceRel = $ds.Relations["DSComparison_SourceTest"]
                $testRel = $ds.Relations["DSComparison_TestSource"]

                }
            } # End of preparation of the relations
            

						# The following is for when there are valid relationships
						# KeyColumns must have been passed in
						# All of the KeyColumns are in both source and target
						# There were no errors loading source and target
            if($KeyColumns -and  $targetRowCount -gt  0 -and $sourceRowCount -gt 0 -and $columnsAllExists -and -not $sourceError -and -not $targetError) { 
            # Walk through each of the rows in the source
            for($i = 0; $i -lt $ds.Tables[$SourceTableName].Rows.Count;$i++){
                $rowColumnErrors = @() # This is where each row error goes
                $row = $ds.Tables[$SourceTableName].Rows[$i]
                $childRows = $row.GetChildRows($sourceRel)



                # Create key for the row.  This will be used in the error message
                $keyvalues = ""
                foreach($keycol in $sourceRel.ParentColumns) {
                    $keycolname = $keycol.ColumnName
                    $keyvalue = $row[$keycolname]
                    $keyvalues += "$keycolname : $keyvalue ;"
                    }
								# This tests for missing child rows
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
                else  {
                	$testMatches +=1
                	
                	# Test the values if there is exactly one row for the key
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
            
            # Walk through the values in the target table, looking for mismatched
            # child rows, which will indicate that there is an extra row or some
            # duplicate
            for($i = 0; $i -lt $ds.Tables[$TargetTableName].Rows.Count;$i++){
                $row = $ds.Tables[$TargetTableName].Rows[$i]
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
        elseif (-not $sourceError -and -not $targetError -and $sourceRowCount -eq 1 -and $targetRowCount -eq 1) {
            # This will involve comparing rows in order.  If there is one value, the results
            # are good.  If there are more, then I won't trust the results as much
            
                 $rowColumnErrors = @()
                 foreach($column in $ds.Tables[$SourceTableName].Columns) {
                    $columnName = $column.ColumnName
                    $parentvalue = $ds.Tables[$SourceTableName].Rows[0][$columnName]
                    $childvalue = $ds.Tables[$TargetTableName].Rows[0][$columnName]
                    if($parentvalue -ne $childvalue) {
                        $rowErrors["RowErrorCount"] +=1
                        $rowColumnErrors += "Mismatch on column $columnName :  Source $parentValue; Test:  $childvalue"
                        }                    
                    }
                    if($rowColumnErrors.Count -gt 0){
                        $rowErrors["SourceRowColumnErrors"]["SingleRow"] = $rowColumnErrors
                    }

            }
					elseif (-not $sourceError -and -not $targetError -and ($sourceRowCount -ne 1 -or $targetRowCount -ne 1)) {
						
						$mainErrors += "Row Count errors:  There are $sourceRowCount rows in the source and $targetRowCount in the target."
						
					}
 


        $ret =[PSCustomObject]@{
            Filter = $Filter
            KeyColumns = $KeyColumns
            SourceRowCount = $sourceRowCount
            SourceTestMatches = $testMatches
            SourceTestDuplicates = $duplicateTestMatches
            SourceTestMissing = $missingTestMatches
            TestRowCount = $targetRowCount
            TestSourceMatches = $sourceMatches
            TestSourceDuplicates = $duplicateSourceMatches
            TestSourceMissing = $missingSourceMatches
            RowErrors = $rowErrors 
            DatasetErrors = $mainErrors
        }

        return , $ret 

    }