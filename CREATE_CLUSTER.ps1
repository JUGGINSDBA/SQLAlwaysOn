$json = get-content C:\sample.json -raw | convertfrom-json
$nodes = $JSON.servers.Name
foreach ($a in $nodes) {
Install-WindowsFeature -Name "failover-clustering" -IncludeManagementTools
write-host "Installing Failover Clustering on $($a)"
}

$clustername = $json.cluster.name
$staticAddress = $json.cluster.StaticIP

$clusterlist = [string]::Join(",",$Nodes)
# $clusterlist = $clusterlist.Insert(0,''').Insert(22,''')


# $clusterlist = $clusterlist.Insert(0,'''').Insert(20,'''')

# New-Cluster -Name $clustername -Node "$($clusterlist)" -StaticAddress $staticAddress

 # New-Cluster -Name $clustername -Node $clusterlist -StaticAddress $staticAddress


$parameters = @{
    Name = $clustername
    Node = $clusterlist
    StaticAddress = $staticaddress
    }


# New-Cluster @parameters

new-cluster -name $clusterName -Node $clusterlist 