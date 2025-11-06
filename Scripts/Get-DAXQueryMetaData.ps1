function Get-DAXQueryMetaData {
    <#
.SYNOPSIS
    Reads the query to find the metadata section of the file

.DESCRIPTION 
    Get-DAXQueryMetaData is a function that takes a DAX Query and reads metadata
    encoded with a comment using JSON

.PARAMETER DAXQuery
    The DAX Query as a string.


.EXAMPLE
    Get-DAXQueryMetaData  -DAXQuery "EVALUATE INFO.VIEW.TABLES()" 


.OUTPUTS
    Object.  It will include position in the string for the comment, the new metadata (merged with old)
    and the old metadata

.NOTES
    Author: Russ Loski

#>
        param (
            [Parameter(Mandatory=$true)][string]$DaxQuery
        )

        # Extract JSON metadata from comments
        $jsonPattern = '(?smi)/\*\*\*\*METADATA\*\*\*(.*?)\*\*\*\*/'
        $jsonMatch = [regex]::Match($DAXQuery, $jsonPattern)
        $queryMetadata = $null
        $start = 0
        $length = 0
        if ($jsonMatch.Success) {
            try {
                $start = $jsonMatch.Index
                $length = $jsonMatch.Length
                $queryMetadata = $jsonMatch.Groups[1].Value | ConvertFrom-Json

            } catch {
                Write-Warning "Failed to parse JSON metadata from DAX query comments."
            }
        }
        if($queryMetadata.OldMetaData) {
            $queryMetadata.psobject.Properties.Remove('OldMetaData')
        }
        return @{
            Start = $start
            Length = $length 
            QueryMetaData = $queryMetadata

        }

}