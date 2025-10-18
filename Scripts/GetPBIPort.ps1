foreach($id in Get-Process -Name msmdsrv|select Id  ) {
Get-NetTCPConnection -State Listen | Where-Object { $_.OwningProcess -eq $Id.Id }


}

 