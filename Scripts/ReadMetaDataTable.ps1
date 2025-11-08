cls

$filename =   "metadata"
$fullFilename = $path + $filename + ".dax"

$DaxQuery = Get-Content -Path $fullFilename -Raw

$tbl1 = Invoke-DAXQuery -DaxQuery $DaxQuery  `
    -ServerName $servers[0].Server 

$tbl2 = Invoke-DAXQuery -DaxQuery $DaxQuery  `
    -ServerName $servers[1].Server  