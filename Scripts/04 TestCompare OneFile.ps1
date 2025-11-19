# Define the connection details and DAX query
cls 
$shortFilename = "Bikes"
$filename =   "$shortFileName.metadata"
$fullFilename = $path + $filename + ".dax"
 


    Write-Output "Processing $filename "
    


    $DaxQuery = Get-Content -Path $fullFilename -Raw

  
    
    $retComparison = Compare-DAXQuery -DaxQuery $DaxQuery  `
    -SourceServer $servers[0].Server -SourceTableName $servers[0].TableName `
    -TargetServer $servers[1].Server -TargetTableName $servers[1].TableName  
 
 
    $newfullFileName = $path + $shortFilename + ".json"

    $retComparison|convertto-json  -depth 15|Out-File -FilePath $newfullFileName

    Write-Output $newfullFileName
    Write-Output "Finished Processing $filename"