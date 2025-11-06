$path = "C:\Users\rlosk\OneDrive\Documents\Clients\SSAS Testing\Queries\"
$servers =  @(
 [PSCustomObject] @{Name="Source" # 3
    Server = "localhost:52482"
    Database = $null
    TableName = "Source Table"

},[PSCustomObject] @{Name="Target" #2
    Server = "localhost:52462"
    Database = $null
    TableName = "Target Table"

},[PSCustomObject] @{Name="Targe2t" #1
    Server = "localhost:52502"
    Database = $null
    TableName = "Target2 Table"

}
)
$testFileName = $path + "MetaData.dax"
$testQuery = Get-Content -path $testFileName -Raw
$testTable = Invoke-DAXQuery -ServerName $servers[0].Server -DaxQuery $testQuery
$testTable