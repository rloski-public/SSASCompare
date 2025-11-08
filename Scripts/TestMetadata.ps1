cls

$filename =   "Month to Date Sales Test.Year_rep"
$fullFilename = $path + $filename + ".dax"

$DaxQuery = Get-Content -Path $fullFilename -Raw

$tbl = Invoke-DAXQuery -DaxQuery $DaxQuery  `
    -ServerName $servers[1].Server -DatabaseName $servers[1].Database 

$ret = New-DAXQueryMetaData -DaxQuery $DaxQuery  `
    -ServerName $servers[1].Server -DatabaseName $servers[1].Database   -ReportName $filename -KeyColumnCount 5