# Define the connection details and DAX query
cls

$filename =   "Product.metadata"
$fullFilename = $path + $filename + ".dax"

$DaxQuery = Get-Content -Path $fullFilename -Raw
 


 #$ret = Get-DAXQueryMetaData -DaxQuery $DaxQuery  
 

$retComparison = Compare-DAXQuery -DaxQuery $DaxQuery  `
    -SourceServer $servers[0].Server -SourceTableName $servers[0].TableName `
    -TestServer $servers[1].Server -TestTableName $servers[1].TableName  
 
 
 $retComparison