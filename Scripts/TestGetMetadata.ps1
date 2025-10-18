# Define the connection details and DAX query
cls

$filename =   "MainPage"
$fullFilename = $path + $filename + ".dax"

$DaxQuery = Get-Content -Path $fullFilename -Raw
 

$ret = New-DAXQueryMetaData -DaxQuery $DaxQuery  `
    -ServerName $servers[0].Server  -ReportName $filename -KeyColumnCount 5
 
 
$newString = Add-DAXQueryMetaData -DaxQuery $DaxQuery -QueryMetaData $ret -Replace 

$newfileName = $path + $filename + ".test.dax"
$newString|Out-File -FilePath $newfileName 



$NewDaxQuery = Get-Content -Path $newfileName -Raw
 
$newMeta = Get-DaxQueryMetaData -DaxQuery $NewDaxQuery