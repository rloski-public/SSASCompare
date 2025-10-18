# Define the connection details and DAX query
cls
$path =   'C:\Users\RussLoski\Documents\Power BI\ModelTesting\'
$filename =   "Bonus.metadata"
$fullFilename = $path + $filename + ".dax"

$DaxQuery = Get-Content -Path $fullFilename -Raw


$ret = Get-DAXQueryMetaData -DaxQuery $DaxQuery  

if ($ret.QueryMetaData) {
    Write-Output "Found"
}
else {

    Write-Output "Not Found"
    }


