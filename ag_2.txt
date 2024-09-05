$PrimaryServer = Get-Item "SQLSERVER:\SQL\SQL01\SQL1,1433"
$SecondaryServer = Get-Item "SQLSERVER:\SQL\SQL02\SQL2,1433"
$PrimaryReplica = New-SqlAvailabilityReplica -Name "SQL01\SQL1" -EndpointUrl "TCP://SQL01.CONTOSO.LOCAL:5022" -FailoverMode "Automatic" -AvailabilityMode "SynchronousCommit" -AsTemplate -Version ($PrimaryServer.Version)
$SecondaryReplica = New-SqlAvailabilityReplica -Name "SQL02\SQL2" -EndpointUrl "TCP://SQL02.CONTOSO.LOCAL:5022" -FailoverMode "Automatic" -AvailabilityMode "SynchronousCommit" -AsTemplate -Version ($SecondaryServer.Version) 
New-SqlAvailabilityGroup -InputObject $PrimaryServer -Name "MainAG" -AvailabilityReplica ($PrimaryReplica, $SecondaryReplica) 
#-Database @("Database01","Database02")

Join-SqlAvailabilityGroup -PATH "SQLSERVER:\SQL\SQL02\SQL2,1433" -Name "MainAG"