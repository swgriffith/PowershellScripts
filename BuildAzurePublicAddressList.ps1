#Login
﻿Login-AzureRmAccount

######################
#Get IaaS Public IPs
######################

$IPs = Get-AzureRMPublicIPAddress

######################
#Get App Service IPs
######################

$WebApps = Get-AzureRmWebApp

$WebAppHostNames = New-Object System.Collections.ArrayList
$WebAppOutboundIPs = New-Object System.Collections.ArrayList

foreach($webapp in $WebApps)
{
    $WebAppHostNames.Add($webapp.EnabledHostNames)
    $WebAppOutboundIPs.Add($webapp.OutboundIpAddresses)
}

######################
#Get API App Service IPs
######################


######################
#Get AppGateway Service Addresses
######################

######################
#Get Load Balancer IPs
######################


######################
#Get Traffice Manager Addresses
######################


######################
#Get API Management Instance IPs
######################




######################
#Build Output
######################
$xml = "<xml>"

foreach($ip in $IPs)
{
    $xml += "<PublicIP>"
    $xml += "<IpAddress>" + $ip.IpAddress + "</IpAddress>"
    $xml += "<Name>" + $ip.Name + "</Name>"
    $xml += "<ResourceGroupName>" + $ip.ResourceGroupName + "</ResourceGroupName>"
    $xml += "<PublicIpAllocationMethod>" + $ip.PublicIpAllocationMethod + "</PublicIpAllocationMethod>"
    $xml += "<Location>" + $ip.Location + "</Location>"
    $xml += "</PublicIP>"
}

$xml += "</xml>"

$xml | out-File -FilePath c:\temp\IPList.xml
