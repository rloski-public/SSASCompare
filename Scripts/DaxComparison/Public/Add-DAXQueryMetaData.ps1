function Add-DAXQueryMetaData {
    <#
.SYNOPSIS
    Adds the metadata to a string

.DESCRIPTION 
    Add-DAXQueryMetaData is a function that takes a DAX Query and adds metadata to the query

.PARAMETER DAXQuery
    The DAX Query as a string.

.PARAMETER QueryMetaData
    This is the metadata object returned by New-DAXQueryMetaData or Get-DAXQueryMetaData

.PARAMETER Replace
    Remove the existing metadata first before adding new metadata

.PARAMETER IncludeExistingMetaData
    Include the Existing MetaData from the object.

.EXAMPLE
    Add-DAXQueryMetaData  -DAXQuery "EVALUATE INFO.VIEW.TABLES()" -QueryMetaData $obj -Replace -IncludeExistingMetaData


.OUTPUTS
    String.  The object will have the first and last characters of the metadata comment

.NOTES
    Author: Russ Loski

#>
        param (
            [Parameter(Mandatory=$true)][string]$DaxQuery,
            [Parameter(Mandatory=$true)][pscustomobject]$QueryMetaData,
            [switch]$Replace,
            [switch]$IncludeExistingMetaData
        )
        $retValue = $DaxQuery

        # Remove the existing text
        if($Replace -and $QueryMetaData -and $QueryMetaData.QueryMetaData `
             -and $QueryMetaData.Length -gt 0){
            $retValue = $retValue.Remove($QueryMetaData.Start, $QueryMetaData.Length)
        }
        # Create the object
        if($QueryMetaData.QueryMetaData){
            $retMetaData =  $QueryMetaData.QueryMetaData
            if($IncludeExistingMetaData -and $QueryMetaData.OldMetaData){
                $oldMetadata = $QueryMetaData.OldMetaData
                $retMetaData|Add-Member -Name OldMetaData -Value $oldMetadata -MemberType NoteProperty
            }
            # Append the metadata
            $retValue =  "/****METADATA***`r`n" + ($retMetaData|convertto-json  -depth 15) +   "`r`n****/`r`n" + $retValue
        }

        return $retValue
}