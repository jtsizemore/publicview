#
#
#

function Invoke-AzureAddFirewallRuleCollections {
    [CmdletBinding()]

    Param
    (
        [Parameter(Mandatory=$true)]
        [string][ValidatePattern('(?i)^.+\.(yaml|yml)$')]$NewCollectionYamlInput,
        [Parameter(Mandatory=$true)]
        [string][ValidatePattern('(?i)^.+\.(yaml|yml)$')]$FirewallInformationYaml,
        [Parameter(Mandatory=$false)]
        [string][ValidateRange(1, 100)]$JsonConversionDepth=100
    )

    # define local variables
    $ErrorAction = "Stop"
    $WarningAction = "SilentlyContinue"
    $InformationACtion = "SilentlyContinue"

    # load existing Azure FW info
    $yamlString = Get-Content -Path $FirewallInformationYaml | Out-String
    $existingAzureFirewallInformationYaml = ConvertFrom-Yaml -Yaml $yamlString -Ordered

    # set Azure context for existing Azure firewall
    $splatSetAzContext =
    @{
        SubscriptionName = $existingAzureFirewallInformationYaml.SubscriptionName
        ErrorAction = $ErrorAction
        WarningAction = $WarningAction
        InformationAction = $InformationAction
    }
    Set-AzContext @$splatSetAzContext | Out-Null

    # get existing Azure firewall object
    $splatGetAzFirewall = 
    @{
        ResourceGroup = $existingAzureFirewallInformationYaml.ResourceGroupName
        Name = $existingAzureFirewallInformationYaml.Name
        ErrorAction = $ErrorAction
        WarningAction = $WarningAction
        InformationAction = $InformationAction
    }
    $azureFirewall = Get-AzureFirewall @splatGetAzFirewall

    # load Azure firewall rule collection info from Yaml file
    $yamlString = Get-Content -Path $NewCollectionYamlInput | Out-String

    # create new Azure firewall rule collection using ConvertFrom-Yaml object
    # results in failure when commiting (Set-AzFirewall) b/c
    # lists/arrays are in wrong format (i.e., no b/w values).
    # workaround is to create object from Yaml then convert Yaml to Json
    # then create final object from Json.
    $tmpYamlObject = ConvertFrom-Yaml -Yaml $yamlString -Ordered
    $tmpJson = ConvertTo-Json -InputObject $tmpYamlObject -Depth $JsonConversionDepth
    $splatNewRuleCollectionDict = 
    @{
        InputObject = $tmpJson
        Depth = $JsonConversionDepth
        AsHashtable = $true
    }
    $newRuleCollection = ConvertFrom-Json @splatNewRuleCollectionDict

    # iterate through rule collection input
    foreach ($collection in $newRuleCollection)
    {
        if ($collection.RuleCollectionType -ieq "nat")
        {
            # create new Azure firewall NAT rule collection object
            $splatNewAzFirewallNatRuleCollection =
            @{
                Name = $collection.Name
                Priority = $collection.Priority
                Rule = $collection.Rules
                ErrorAction = $ErrorAction
                WarningAction = $WarningAction
                InformationAction = $InformationAction
            }
            $newNatRuleCollection =
            New-AzFirewallNatRuleCollection @splatNewAzFirewallNatRuleCollection
            # add collection object to existing Azure firewall object
            $azureFirewall.NatRuleCollections.Add($newNatRuleCollection)
        }
        if ($collection.RuleCollectionType -ieq "network")
        {
            # create new Azure firewall network rule collection object
            $splatNewAzFirewallNetworkRuleCollection =
            @{
                Name = $collection.Name
                Priority = $collection.Priority
                Rule = $collection.Rules
                ActionType = $collection.Action.Type
                ErrorAction = $ErrorAction
                WarningAction = $WarningAction
                InformationAction = $InformationAction
            }
            $newNetworkRuleCollection = 
            New-AzFirewallNetworkRuleCollection @splatNewAzFirewallNetworkRuleCollection
            # add collection object to existing Azure firewall object
            $azureFirewall.NetworkRuleCollections.Add($newNetworkRuleCollection)
        }
        if ($collection.RuleCollectionType -ieq "application")
        {
            # create new Azure firewall application rule collection object
            $splatNewAzFirewallApplicationRuleCollection =
            @{
                Name = $collection.Name
                Priority = $collection.Priority
                Rule = $collection.Rules
                ActionType = $collection.Action.Type
                ErrorAction = $ErrorAction
                WarningAction = $WarningAction
                InformationAction = $InformationAction
            }
            $newApplicationRuleCollection =
            New-AzFirewallApplicationRuleCollection @splatNewAzFirewallApplicationRuleCollection
            # add collection object to existing Azure firewall object
            $azureFirewall.ApplicationRuleCollections.Add($newApplicationRuleCollection)
        }
    }
    # commit Azure firewall changes
    $splatSetAzFirewall =
    @{
        AzureFirewall = $azureFirewall
        ErrorAction = $ErrorAction
        WarningAction = $WarningAction
        InformationAction = $InformationAction
    }
    Set-AzFirewall @splatSetAzFirewall | Out-Null
}
