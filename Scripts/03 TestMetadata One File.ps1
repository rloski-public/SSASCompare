cls

$filename =   "bikes"
$fullFilename = $path + $filename + ".dax"

$DaxQuery = Get-Content -Path $fullFilename -Raw
# View the basic datatable
$tbl = Invoke-DAXQuery -DaxQuery $DaxQuery  `
    -ServerName $servers[0].Server # -DatabaseName $servers[1].Database 
$tbl

# Create metadata file

 # Read the metadata from the file, using the second server as the model
    $ret = New-DAXQueryMetaData -DaxQuery $DaxQuery  `
        -ServerName $servers[0].Server  `
        -ReportName $filename -KeyColumnCount 5
 
    # Create a new string that merges metadata and the existing query
    $newString = Add-DAXQueryMetaData -DaxQuery $DaxQuery -QueryMetaData $ret -Replace 

    # Write the new query to a file with metadata in name 
    $newfileName = [System.IO.Path]::Combine($path,  $filename + ".metadata.dax")
    $newString|Out-File -FilePath $newfileName 
    Write-Output "Finished Processing $filename"