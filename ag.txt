Import-Module SQLServer
 
# Restore-SqlDatabase -Database "MyNewDB" -BackupFile "C:\SQL\MyNewDB.bak" -ServerInstance "SQLNode1\INST1" -RestoreAction database -NoRecovery
 
$primaryServer = Get-SqlInstance -ServerInstance "SQL01\SQL1,40001"
$secondaryserver = Get-SqlInstance -ServerInstance "SQL02\SQL2,40002"

$A = $primaryserver.InstanceName
$Z = $secondaryserver.InstanceName
$b = $primaryserver.Version
$c = "SQL01"
$d = "SQL02"
 
$ServerObject = Get-Item "SQLSERVER:\Sql\sql01\sql1"

#$primaryReplica = New-SqlAvailabilityReplica -Name "$($c)\$($a)" `
#-EndpointUrl "TCP://SQL01.contoso.local:5022" -FailoverMode Automatic `
#-AvailabilityMode "SynchronousCommit" -AsTemplate -Version ($primaryserver.version) `
 
New-SqlAvailabilityReplica -Name "SQL01\SQL1" -EndpointUrl "TCP://SQL01.contoso.local:5022" -FailoverMode Automatic -AvailabilityMode SynchronousCommit -AsTemplate -Version $ServerObject.version


    
$secondaryReplica = New-SqlAvailabilityReplica -Name "$($d)\$($z)" `
    -EndpointUrl "TCP://SQL02.contoso.local:5022" -FailoverMode `
    "Automatic" -AvailabilityMode "SynchronousCommit" `
    -AsTemplate -Version ($secondaryServer.Version)
 
New-SqlAvailabilityGroup -Name "AG10" `
    -Path "SQLSERVER:\SQL\SQL01\SQL,40001" `
    -AvailabilityReplica @($primaryReplica) 
   # -AvailabilityReplica @($primaryReplica,$secondaryReplica) 
    #-Database "MyNewDB"
    
Join-SqlAvailabilityGroup -Path "SQLSERVER:\SQL\SQL02\SQL2,1433" -Name "AGusingPowerShell"
Add-SqlAvailabilityDatabase -Path "SQLSERVER:\SQL\SQLNode1\INST1\AvailabilityGroups\AGusingPowerShell" -Database "MyNewDB"
 
New-SqlAvailabilityGroupListener -Name AGusingPowerShell `
    -StaticIp '10.0.2.25/255.255.255.0' -Path "SQLSERVER:\SQL\SQLNode2\INST1\AvailabilityGroups\AGusingPowerShell" `
    -Port 3333