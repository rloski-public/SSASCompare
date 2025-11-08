CD "C:\Users\rlosk\OneDrive\Documents\Clients\SSAS Testing\Scripts"
# Remove-Module "DAXComparison" 
Import-Module .\DaxComparison\DAXComparison.psm1
$path = "C:\Users\rlosk\OneDrive\Documents\Clients\SSAS Testing\Queries\"
$servers =  @(
 [PSCustomObject] @{Name="Source" # 3
    Server = "localhost:62483"
#    Database = "SourceDatabase"
    TableName = "Source Table"

},[PSCustomObject] @{Name="Target" #2
    Server = "localhost:50779"
#    Database = "TargetDatabas"
    TableName = "Target Table"

}
)
 