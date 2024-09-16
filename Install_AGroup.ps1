# How many Replicas initially - possibly 2 or 3 ?


Import-Module SQLServer

$primaryServer = Get-Item "SQLSERVER:\SQL\SQL01\SQL1,40001" 
$secondaryServer = Get-Item "SQLSERVER:\SQL\SQL02\SQL2,40002"
$thirdserver = Get-Item "SQLSERVER:\SQL\SQL03\SQL2,40003"
$agGroup = "AG01"
$Listener = "AGListener"
 
$primaryReplica = New-SqlAvailabilityReplica -Name "SQL01\SQL1" `
    -EndpointUrl "TCP://SQL01.contoso.local:5022" -FailoverMode Automatic `
    -AvailabilityMode "SynchronousCommit" `
    -SeedingMode Automatic `
    -AsTemplate -Version ($primaryServer.Version) `
    
$secondaryReplica = New-SqlAvailabilityReplica -Name "SQL02\SQL2" `
    -EndpointUrl "TCP://SQL02.contoso.local:5022" -FailoverMode "Automatic" `
     -AvailabilityMode "SynchronousCommit" `
    -SeedingMode Automatic `
    -AsTemplate -Version ($secondaryServer.Version)

$thirdReplica = New-SqlAvailabilityReplica -Name "SQL03\SQL2" `
    -EndpointUrl "TCP://SQL03.contoso.local:5022" -FailoverMode `
    "Automatic" -AvailabilityMode "SynchronousCommit" `
    -SeedingMode Automatic `
    -AsTemplate -Version ($thirdserver.Version)
 
# New-SqlAvailabilityGroup -Name "AGusingPowerShell" `
New-SqlAvailabilityGroup -Name ($agGroup) `
    -Path "SQLSERVER:\SQL\SQL01\SQL1,40001" `
    -AvailabilityReplica @($primaryReplica,$secondaryReplica,$thirdReplica) 
      
Join-SqlAvailabilityGroup -Path "SQLSERVER:\SQL\SQL02\SQL2,40002" -Name "$($agGroup)"
Join-SqlAvailabilityGroup -Path "SQLSERVER:\SQL\SQL03\SQL2,40003" -Name "$($agGroup)"
 
#Possibility of additional listener in subnet

New-SqlAvailabilityGroupListener -Name ($Listener) `
    -StaticIp '10.0.0.25/255.255.255.0' -Path "SQLSERVER:\SQL\SQL01\SQL1,40001\AvailabilityGroups\$($agGroup)" `
    -Port 3333

$myJSON = Get-Content c:\test.json | ConvertFrom-Json

## Code below here needs rewriting to be more efficient
## JSON file may need to be reformatted.

$a = $myjson.instance1.server
$b = $myjson.instance1.instance
$c = $myjson.instance1.port

$query = "ALTER AVAILABILITY GROUP [AG01] GRANT CREATE ANY DATABASE"

#foreach ($z in $myJSON)
    #     {
 write-host "invoke-sqlcmd -serverinstance $($a)\$($b),$c -query $query"
        invoke-sqlcmd -serverinstance "$($a)\$($b),$c" -query $query -Encrypt Optional
#        }

$a = $myjson.instance2.server
$b = $myjson.instance2.instance
$c = $myjson.instance2.port

$query = "ALTER AVAILABILITY GROUP [AG01] GRANT CREATE ANY DATABASE"

#foreach ($z in $myJSON)
    #     {
 write-host "invoke-sqlcmd -serverinstance $($a)\$($b),$c -query $query"
        invoke-sqlcmd -serverinstance "$($a)\$($b),$c" -query $query -Encrypt Optional
#        }

$a = $myjson.instance3.server
$b = $myjson.instance3.instance
$c = $myjson.instance3.port

$query = "ALTER AVAILABILITY GROUP [AG01] GRANT CREATE ANY DATABASE"

#foreach ($z in $myJSON)
    #     {
 write-host "invoke-sqlcmd -serverinstance $($a)\$($b),$c -query $query"
        invoke-sqlcmd -serverinstance "$($a)\$($b),$c" -query $query -Encrypt Optional
#        }
