# Write file
$filename =   "MonthlySales.main"
$fullFilename = $path + $filename + ".dax"
$csvFile  = $path + $filename + ".output.csv"
$jsonFile  = $path + $filename + ".output.json"



$DaxQuery = Get-Content -Path $fullFilename -Raw

$tbl = Invoke-DAXQuery -DaxQuery $DaxQuery  `
    -ServerName $servers[0].Server 

$tbl|Export-Csv -Path $csvFile -NoTypeInformation

$tbl.Row | ConvertTo-Json -Depth 10 |Out-File -FilePath $jsonFile
    