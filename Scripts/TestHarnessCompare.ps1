# Define the connection details and DAX query
cls

$filename =   "Month to Date Sales Test.Year_rep.metadata"
$fullFilename = $path + $filename + ".dax"

 
    $shortFilename = $filename.Substring(0,$filename.Length - $metadatanamelen)

    Write-Output "Processing $filename to $shortFileName"
    


    $DaxQuery = Get-Content -Path $fullFilename -Raw

    $tbl = Invoke-DAXQuery -DaxQuery $DaxQuery  `
    -ServerName $servers[0].Server -DatabaseName $servers[0].Database   
  
    
    $retComparison = Compare-DAXQuery -DaxQuery $DaxQuery  `
    -SourceServer $servers[0].Server -SourceTableName $servers[0].TableName `
    -TargetServer $servers[1].Server -TargetTableName $servers[1].TableName  
 
 
    $newfullFileName = $path + $shortFilename + ".json"

    $retComparison|convertto-json  -depth 15|Out-File -FilePath $newfullFileName

    Write-Output $newfullFileName
    Write-Output "Finished Processing $filename"