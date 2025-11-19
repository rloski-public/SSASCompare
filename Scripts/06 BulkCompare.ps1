cls
$filestoProcess = Get-ChildItem -Path $path -Filter "*.metadata.dax"

$metadatanamelen = ".metadata".Length
foreach($fileitem in $filestoProcess) {
    $filename =   [System.IO.Path]::GetFileNameWithoutExtension($fileitem.Name)
    $shortFilename = $filename.Substring(0,$filename.Length - $metadatanamelen)

    Write-Output "Processing $filename to $shortFileName"
    $fullFilename = $fileitem.FullName


    $DaxQuery = Get-Content -Path $fullFilename -Raw
  
    
    $retComparison = Compare-DAXQuery -DaxQuery $DaxQuery  `
    -SourceServer $servers[0].Server -SourceTableName $servers[0].TableName `
    -TargetServer $servers[1].Server -TargetTableName $servers[1].TableName  
 
 
    $newfullFileName = $path + $shortFilename + ".json"

    $retComparison|convertto-json  -depth 15|Out-File -FilePath $newfullFileName

    Write-Output $newfullFileName
    Write-Output "Finished Processing $filename"

}