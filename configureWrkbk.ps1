#configure workbook

function populateHost{
    $hostTable = @()

    $clusters = Get-Cluster
    foreach($currCluster in $clusters){

        $hosts = $currCluster | Get-VMHost
        foreach($currHost in $hosts){

            #this is to get adapter, ipaddress, subnetmask, defaultgateway, vlanid
            $cnet = $currHost | Get-VMHostNetworkAdapter | select name, ip, subnetmask, ipv6, dhcpenabled
            $nets = $cnet | Where-Object {$_.IP -ne ""} 
            $mgmtIP = $nets | Where-Object {$_.name -eq "vmk0"}

            if(!$mgmtIP.dhcpenabled){
                $ipv4mode = "Static IPv4 Address"
            } else {
                $ipv4mode = "Dynamic IPv4 Address"
            }
            
            $ip6 = $mgmtIP.ipv6 | select address -ExpandProperty address

            if($ip6.length -eq 3){
                $primaryip6 = $ip6[0]
                $secondaryip6 = $ip6[1]
                $thirdip6 = $ip6[2]
                if(!$mgmtIP.dhcpenabled){
                    $ipv6mode = "Static IPv6 Address"
                } else {
                    $ipv6mode = "Dynamic IPv6 Address"
                }
            } elseif($ip6.length -eq 2) {
                $primaryip6 = $ip6[0]
                $secondaryip6 = $ip6[1]
                $thirdip6 = "n/a"
                if(!$mgmtIP.dhcpenabled){
                    $ipv6mode = "Static IPv6 Address"
                } else {
                    $ipv6mode = "Dynamic IPv6 Address"
                }
            } elseif($ip6.length -eq 1) {
                $primaryip6 = $ip6[0]
                $secondaryip6 = "n/a"
                $thirdip6 = "n/a"
                if(!$mgmtIP.dhcpenabled){
                    $ipv6mode = "Static IPv6 Address"
                } else {
                    $ipv6mode = "Dynamic IPv6 Address"
                }
            } else {
                $primaryip6 = "n/a"
                $secondaryip6 = "n/a"
                $thirdip6 = "n/a"
                $ipv6mode = "Disable IPv6 Configuration"
            }

            $defaultGateway = $currHost.ExtensionData.Config.Network.IpRouteConfig.DefaultGateway
            $dvpg = Get-VirtualPortGroup -Distributed -Name "hello"
            $dvpgvid = $dvpg.ExtensionData.Config.DefaultPortConfig.Vlan.VlanId

            #this is to get primary and secondary dns servers and search domain
            $dnses = $currHost | Get-VMHostNetwork | select dnsaddress, searchdomain
            $dns = $dnses.dnsaddress
            $suff = $dnses.searchdomain[0]
            if($dns.length -eq 2){
                $primaryDNS = $dns[0]
                $secondaryDNS = $dns[1]
            } else {
                $primaryDNS = $dns
                $secondaryDNS = " "
            }
        
            #this is to get time configurations
            $ntpserver = $currHost | Get-VMHostNtpServer
            #$ntpserver

            #this is to get authentication services
            $dom = Get-VMHostAuthentication -VMHost $currHost
            #$dom.domain

            #this is to get the host profile
            $hostProfile = $currHost | Get-VMHostProfile
            #$hostProfile.name

            #Write-Output "hostname: $($currHost.name) `nadaptername: $($mgmtIP.name) `nipaddress: $($mgmtIP.ip) `nsubnetmask: $($mgmtIP.subnetmask) `ndefaultgateway: $($defaultGateway) `nip6address1: $($primaryip6) `nip6address2: $($secondaryip6) `nvladid: $($dvpgvid) `nprimaryDNS: $($primaryDNS) `nsecondaryDNS: $($secondaryDNS) `n`n"
            $tempAdd = New-Object esxihost($currCluster, $mgmtip.name, $dvpgvid, $ipv4mode, $mgmtIP.ip, $mgmtIP.subnetmask, $defaultGateway, $ipv6mode, $primaryip6, $secondaryip6, $thirdip6, "need to get", $primaryDNS, $secondaryDNS, $currHost.name, $suff, "need to get", "need to get", "need to get", "need to get", $ntpserver, $dom.Domain, "need to get", "need to get", $hostProfile.Name)
            #$tempAdd
            $hostTable += $tempAdd
        }

    }
    #$hostTable += $tempAdd

    return $hostTable
}

function printTable{
    $hostTable = populateHost
    $hostTable | Export-Csv red.csv -NoTypeInformation
    #$pls = Import-Csv .\red.csv
    #$pls | ConvertFrom-Csv | fl | Out-File .\red1.csv
    #$hostTable | Export-Csv .\red1.csv -NoTypeInformation | Format-List
}
