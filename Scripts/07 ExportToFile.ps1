# Write file
$filename =   "MonthlySales.main"
$fullFilename = $path + $filename + ".dax"
$csvFile  = $path + $filename + ".output.csv"


$DaxQuery = Get-Content -Path $fullFilename -Raw

$tbl = Invoke-DAXQuery -DaxQuery $DaxQuery  `
    -ServerName $servers[0].Server 

$tbl|Export-Csv -Path $csvFile -NoTypeInformation


    