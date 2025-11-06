# Define the connection details and DAX query
cls

$filename =   "Aging Inventory.Rev.20240923"
$fullFilename = $path + $filename + ".dax"

$DaxQuery = Get-Content -Path $fullFilename -Raw
 

$ret = New-DAXQueryMetaData -DaxQuery $DaxQuery  `
    -ServerName $servers[1].Server -DatabaseName $servers[1].Database   -ReportName $filename -KeyColumnCount 5
 
 
$newString = Add-DAXQueryMetaData -DaxQuery $DaxQuery -QueryMetaData $ret -Replace 

$newfileName = $path + $filename + ".metadata.dax"
$newString|Out-File -FilePath $newfileName 



$NewDaxQuery = Get-Content -Path $newfileName -Raw
 
$newMeta = Get-DaxQueryMetaData -DaxQuery $NewDaxQuery