Class esxihost{
    #properties
    [String] $mgmtNetworkID
    [String] $vlanID
    [String] $ipv4Mode
    [String] $ipv4Addr
    [String] $ipv4Subnet
    [String] $ipv4DefaultGateway
    [String] $ipv6Mode
    [String] $ipv6StaticAddr1
    [String] $ipv6StaticAddr2
    [String] $ipv6StaticAddr3
    [String] $ipv6DefaultGateway
    [String] $primaryDNS
    [String] $secondaryDNS
    [String] $hostname
    [String] $customDNSSuffix
    [String] $swapFileLocation
    [String] $defaultVMCompatibility
    [String] $timeConfig
    [String] $ntpServiceStartUpPolicy
    [String] $ntpServers
    [String] $domain
    [String] $credentials
    [String] $usingProxy
    [String] $hostProfile

    #constructor
    esxihost([string]$imgmtnetworkid, [string]$ivlanid, [string]$iipv4mode, [string]$iipv4addr, [string]$iipv4sub, [string]$iipv4defaultgateway, 
            [string]$iipv6mode, [string]$iipv6addr1, [string]$iipv6addr2, [string]$iipv6addr3, [string]$iipv6defaultgateway, 
            [string]$iprimarydns, [string]$isecondarydns, [string]$ihostname, [string]$icustomdnssuffix, [string]$iswapfileloc, [string]$idefaultvmcompat, 
            [string]$itimeconfig, [string]$intpstartuppol, [string]$intpservers, [string]$idomain, [string]$icreds, [string]$iusingproxy, [string]$ihostprofile){
        
        $this.mgmtNetworkID = $imgmtnetworkid
        $this.vlanID = $ivlanid
        $this.ipv4Mode = $iipv4mode
        $this.ipv4Addr = $iipv4addr
        $this.ipv4Subnet = $iipv4sub
        $this.ipv4DefaultGateway = $iipv4defaultgateway
        $this.ipv6Mode = $iipv6mode
        $this.ipv6StaticAddr1 = $iipv6addr1
        $this.ipv6StaticAddr2 = $iipv6addr2
        $this.ipv6StaticAddr3 = $iipv6addr3
        $this.ipv6DefaultGateway = $iipv6defaultgateway
        $this.primaryDNS = $iprimarydns
        $this.secondaryDNS = $isecondarydns
        $this.hostname = $ihostname
        $this.customDNSSuffix = $icustomdnssuffix
        $this.swapFileLocation = $iswapfileloc
        $this.defaultVMCompatibility = $idefaultvmcompat
        $this.timeConfig = $itimeconfig
        $this.ntpServiceStartUpPolicy = $intpstartuppol
        $this.ntpServers = $intpservers
        $this.domain = $idomain
        $this.credentials = $icreds
        $this.usingProxy = $iusingproxy
        $this.hostProfile = $ihostprofile
    }
}