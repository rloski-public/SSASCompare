# Set this path to the location of your files
cls
$path = "C:\Users\rlosk\OneDrive\Documents\Clients\SSAS Testing\FinalProject\SSASCompare\SampleDAXQueries\"
get-childitem $path

# Open reports one by one and run the following.  

Find-PBIPorts

$servers =  @(
 [PSCustomObject] @{Name="Source" # 3
    Server = "localhost:54814"
#    Database = "SourceDatabase"
    TableName = "Source Table"

},[PSCustomObject] @{Name="Target" #2
    Server = "localhost:49220"
#    Database = "TargetDatabas"
    TableName = "Target Table"

}
)

# Test the variables

cls

$filename =   "metadata"
$fullFilename = $path + $filename + ".dax"

$DaxQuery = Get-Content -Path $fullFilename -Raw

$tbl1 = Invoke-DAXQuery -DaxQuery $DaxQuery  `
    -ServerName $servers[0].Server 
    
$tbl1

$tbl2 = Invoke-DAXQuery -DaxQuery $DaxQuery  `
    -ServerName $servers[1].Server  
$tbl2
