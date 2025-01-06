import-module sqlserver

$configData = get-content c:\final.json -Raw | ConvertFrom-Json
$Replicas = $configData.Replicas
$sqlInstance = $configData.Replicas.InstanceName
$sqlPort = $configData.Replicas.Port

foreach ($z in $Replicas.Name){

$reg = (Get-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL15.$($sqlInstance)\MSSQLServer\HADR") # -name HADR_ENABLED) | Where-Object -Property "hadr_ENABLED" 

read-host "reg is $($reg.hadr_enabled)"

$hadrcheck = ($reg.hadr_enabled)


$HADRCHECK  = Invoke-Command -ComputerName $z -ScriptBlock {
   (Get-ItemProperty -path $reg) 
   }   

write-host "hadrcheck is $($hadrcheck)"


if($hadrcheck -eq 1){write-host "it is enabled on server $($z) -- good news !!"
}

else{write-host "on $($Z) it is NOT enabled"

write-host "will need to enable"

$srvConnect = New-Object Microsoft.SqlServer.Management.Smo.Server "$($z)\$($sqlInstance),$($sqlPort)"
Enable-DbaAgHadr -sqlinstance $srvConnect -Force -Confirm:$false
}

}
