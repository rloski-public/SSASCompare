function New-DAXQueryMetaData {
    <#
.SYNOPSIS
    Runs the DAX Query and identifies metadata from that query

.DESCRIPTION 
    New-DAXQueryMetaData is a function that takes a DAX Query and connection
    information (Server and Database) and runs it.  It gather a list of columns
    that can be used for querying a datatable created using the DAX Query.  It
    also identifies likely relationships and filters for comparing the DAX Query
    against multiple environments

.PARAMETER ReportName
    The SSAS server name for running the query.

.PARAMETER ServerName
    The SSAS server name for running the query.

.PARAMETER DatabaseName
    The SSAS database to run the query on.

.PARAMETER DAXQuery
    The DAX Query as a string.

.PARAMETER EffectiveUserName
    This is used to pass in the user information, in whose context the query is run.  This is used 
    to test Row Level Security (RLS)

.PARAMETER KeyColumnCount
    How many columns are in the key?  If there are boolean columns, they are most commonly identify
    the number key columns.  KeyColumnCount is used if there are no boolean columns

.EXAMPLE
    New-DAXQueryMetaData -ServerName "ProdServer" -DatabaseName "ModelDB" -DAXQuery "EVALUATE INFO.VIEW.TABLES()" `
        -EffectiveUserName "User1" -KeyColumnCount 5


.OUTPUTS
    Custom object.  The object has the location of the existing metadata as well as the new metadata and 
    old metadata

.NOTES
    Author: Russ Loski
    I would like to be able to merge the old metadata with the new metadata and then replace the code in 
    the metadata with the new metadata.  But there might be reasons to keep the old metadata if there is
    a change.

#>
        param (
            [string]$ReportName ,
            [Parameter(Mandatory=$true)][string]$ServerName,
            [string]$DatabaseName,
            [Parameter(Mandatory=$true)][string]$DaxQuery,
            [string]$EffectiveUserName,
            [int]$KeyColumnCount = 5 # This will be used if there are no boolean columns

        )

# Parse the DaxQuery to find the metadata portion
$existingmetadata = Get-DAXQueryMetaData -DaxQuery $DAXQuery

# Get the start and length of existing metadata
if($existingmetadata){
    $start = $existingmetadata.Start
    $length = $existingmetadata.Length
    $oldmetadata = $existingmetadata.QueryMetaData
}
else {
    $start = 0
    $length = 0
}

# Get the Report name 
if ([string]::IsNullOrEmpty($ReportName)){
    if($oldmetadata -and $oldmetadata.ReportName){
       $ReportName = $oldmetadata.ReportName
    }
    else {
        $ReportName = "Unknown"
    }

}




# Run the query to get the metadata
$ret = Invoke-DAXQuery -DaxQuery $DaxQuery  `
    -ServerName $ServerName -DatabaseName $DatabaseName `
    -EffectiveUserName $EffectiveUserName
 
 
# Create a list of the columns, with the FilterName column as one of the values 
$columns = &{for($i = 0; $i -lt $ret.Columns.Count; $i++){
    [PSCustomObject]($ret.Columns[$i]|Select @{n="ColumnOrder";e={$i}},ColumnName `
        ,@{n="Datatype";e={$_.Datatype.ToString()}} `
        , @{n="FilterName";e={$_.ColumnName.Replace("[","[[").Replace("]","\]]")}})
    }

}

# Get a list of the boolean columns
 
$Booleans =  $columns|where DataType -eq "System.Boolean" 


if($Booleans) {
    $firstBoolean = ($Booleans|Sort-Object ColumnOrder|Select-Object -Property ColumnOrder -First 1).ColumnOrder
}
else {
    $firstBoolean = $KeyColumnCount
}


# Get the old filterset
if($oldmetadata -and $oldmetadata.FilterSets){
    $FilterSets = $oldmetadata.FilterSets
}
else {
    $FilterSets = @()
}

# If the last column is the column index, then add it as the filter for the total and 
# as part of the filter for the detail


[array]$columnKeyColumnArray =  $Columns|Where-Object ColumnName -eq "[ColumnIndex]"|Select -ExpandProperty ColumnName

# If there is no total set, then create it
# Create the object for the total set.  This will create DataView where all of the booleans are true

if(($FilterSets|Where-Object Name -eq "TotalSet").Count -eq 0){
    $totalSetObject = [PSCustomObject]@{
    Name="TotalSet"
    Filter= ($Booleans|foreach {$_.FilterName + " = true"}) -join " and "
    }

    # Add the columnKeyColumnArray
    if ($columnKeyColumnArray) {
        $totalSetObject | Add-Member -Type NoteProperty -Name "KeyColumns" -Value  $columnKeyColumnArray
    }
    
    # Add the totalSetObject to the $FilterSets
    $FilterSets += $totalSetObject

}


# If there is no DetailSet
# Create the object for the detail set.  This will create DataView where all of the booleans are false

if(($FilterSets|Where-Object Name -eq "DetailSet").Count -eq 0){
    [array]$keyColumnArray =  $Columns|Where-Object ColumnOrder -lt $firstBoolean|Sort-Object ColumnOrder |Select -ExpandProperty ColumnName
    $keyColumnArray +=$columnKeyColumnArray

    $FilterSets += [PSCustomObject]@{
    Name="DetailSet"
    Filter= ($Booleans|foreach {$_.FilterName + " = false"}) -join " and "
    KeyColumns =  $keyColumnArray
    }
}

$metadata = [pscustomobject]@{
    ReportName = $ReportName
    FilterSets =  $FilterSets
    Columns = $columns|Sort-Object ColumnOrder
}

$retvalue = @{
            Start = $start
            Length = $length 
            QueryMetaData = $metadata
            OldMetaData = $oldmetadata
        }


return $retvalue 
}