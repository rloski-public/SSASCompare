# Define the connection details and DAX query
cls
$filestoProcess = Get-ChildItem -Path $path -Filter "*.dax"

foreach($fileitem in $filestoProcess) {
    $filename =   [System.IO.Path]::GetFileNameWithoutExtension($fileitem.Name)

    Write-Output "Processing $filename"
    $fullFilename = $fileitem.FullName
    
    # Get the contents of the file 
    $DaxQuery = Get-Content -Path $fullFilename -Raw 

    # Read the metadata from the file, using the second server as the model
    $ret = New-DAXQueryMetaData -DaxQuery $DaxQuery  `
        -ServerName $servers[1].Server -DatabaseName $servers[1].Database  `
        -ReportName $filename -KeyColumnCount 5
 
    # Create a new string that merges metadata and the existing query
    $newString = Add-DAXQueryMetaData -DaxQuery $DaxQuery -QueryMetaData $ret -Replace 

    # Write the new query to a file with metadata in name 
    $newfileName = [System.IO.Path]::Combine($path,  $filename + ".metadata.dax")
    $newString|Out-File -FilePath $newfileName 
    Write-Output "Finished Processing $filename"

}
 


 

