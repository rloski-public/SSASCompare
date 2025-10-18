# Define the connection details and DAX query
cls
$path =   'C:\Users\RussLoski\Documents\Power BI\ModelTesting\'
$filename =   "Bonus"
$fullFilename = $path + $filename + ".dax"

$DaxQuery = Get-Content -Path $fullFilename -Raw
 

$servers =  @(
 [PSCustomObject] @{Name="Apex-BI01"
    Server = "Apex-BI01"
    Database = "ApexDW"
    TableName = "ApexBI01"

},[PSCustomObject] @{Name="Dev-Reports02"
    Server = "Dev-Reports02"
    Database = "ApexDW"
    TableName = "DevReports02"

}
)
 
$ret = Invoke-DAXQuery -DaxQuery $DaxQuery  `
    -ServerName $servers[0].Server -DatabaseName $servers[0].Database  
 
 
# Create a list of the columns, with the Filter column as one of the values 
$columns = &{for($i = 0; $i -lt $ret.Columns.Count; $i++){
    [PSCustomObject]($ret.Columns[$i]|Select @{n="ColumnOrder";e={$i}},ColumnName `
        ,@{n="Datatype";e={$_.Datatype.ToString()}} `
        , @{n="FilterName";e={$_.ColumnName.Replace("[","[[").Replace("]","\]]")}})
    }

}

# Find the first of the Boolean columns
 
$Booleans =  $columns|where DataType -eq "System.Boolean" 
$firstBoolean = ($Booleans|Sort-Object ColumnOrder|Select-Object -Property ColumnOrder -First 1).ColumnOrder



$totalSet = [PSCustomObject]@{
    Name="TotalSet"
    Filter= ($Booleans|foreach {$_.FilterName + " = true"}) -join " and "
    }
$detailSet = [PSCustomObject]@{
    Name="DetailSet"
    Filter= ($Booleans|foreach {$_.FilterName + " = false"}) -join " and "
    KeyColumns =  $Columns|Where-Object ColumnOrder -lt $firstBoolean|Sort-Object ColumnOrder|foreach {$_.ColumnName}
    }

$metadata = @{
    ReportName = $filename
    FilterSets =  @( 
        $totalSet, $detailSet

    )
    Columns = $columns|Sort-Object ColumnOrder
}

$daxMetadata = "/****METADATA***`r`n" + ($metadata|convertto-json ) +  "`r`n*/`r`n"

$newFile = $path + $filename + ".metadata.dax"
$daxMetadata + $DaxQuery |Out-File $newFile


<# The following is my target, including the SQL multiline comment
/*
[
{"Name":"TotalSet",
"Filter":"[[IsGrandTotalRowTotal\\]] = true AND [[IsDM1Total\\]]= true AND [[IsDM3Total\\]] = true"
}
,
{"Name":"DivisionSet",
"Filter":"[[IsGrandTotalRowTotal\\]] = false AND [[IsDM1Total\\]]= true AND [[IsDM3Total\\]] = true",
"KeyColumns":["SalesRepTerritory[Division]","SalesRepTerritory[Division_order]"]
}
,
{"Name":"BonusSalesRepSet",
"Filter":"[[IsGrandTotalRowTotal\\]] = false AND [[IsDM1Total\\]]= false AND [[IsDM3Total\\]] = true",
"KeyColumns":["SalesRepTerritory[Division]","SalesRepTerritory[Division_order]","SalesRepTerritory[BonusSalesRepName]"]
}
,
{"Name":"DetailSet",
"Filter":"[[IsGrandTotalRowTotal\\]] = false AND [[IsDM1Total\\]]= false AND [[IsDM3Total\\]] = false",
"KeyColumns":["SalesRepTerritory[Division]","SalesRepTerritory[Division_order]","SalesRepTerritory[BonusSalesRepName]","SalesRepTerritory[TerritoryName]"]
},
{"Name":"Test",
"Filter":"[[IsGrandTotalRowTotal\\]] = false AND [[IsDM1Total\\]]= false AND [[IsDM3Total\\]] = false",
"KeyColumns":["SalesRepTerritory[Division]","SalesRepTerritory[Division_order]","SalesRepTerritory[BonusSalesRepName24]","SalesRepTerritory[TerritoryName]"]
}
]

*/
#>