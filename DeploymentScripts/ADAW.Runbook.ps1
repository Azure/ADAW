Param
(
    [Parameter (Mandatory = $true)]
    [string] $targetResourceGroup,

    [Parameter (Mandatory = $true)]
    [string] $targetResourceGroupLocation,

    [Parameter (Mandatory = $true)]
    [object] $targetResourceGroupTags,

    [Parameter (Mandatory = $true)]
    [string] $targetSubscription,

    [Parameter (Mandatory = $true)]
    [string] $projectPrefix,

    [Parameter (Mandatory = $true)]
    [string] $securityOwnerAADLogin,

    [Parameter (Mandatory = $true)]
    [string] $securityOwnerAADId,

    [Parameter (Mandatory = $true)]
    [string] $securityAlertEmail,

    [Parameter (Mandatory = $true)]
    [string] $vNetPrefix,

    [Parameter (Mandatory = $true)]
    [string] $subnetControlPlanePrefix,

    [Parameter (Mandatory = $true)]
    [string] $subnetDataPlanePrefix,

    [Parameter (Mandatory = $true)]
    [string] $subnetPrivateLinkPrefix,

    [Parameter (Mandatory = $false)]
    [string] $virtualApplianceIPAddress,

    [Parameter (Mandatory = $true)]
    [string] $sqlServerDBSkuName,

    [Parameter (Mandatory = $true)]
    [string] $sqlServerDBTierName,

    [Parameter (Mandatory = $true)]
    [string] $logRetentionInDays,

    [Parameter (Mandatory = $false)]
    [string] $ADAWTemplateSpecName = 'ADAW',

    [Parameter (Mandatory = $false)]
    [string] $ADAWTemplateSpecVersion = '1.0',

    [Parameter (Mandatory = $false)]
    [string] $ADAWTemplateSpecResourceGroup,

    [Parameter (Mandatory = $false)]
    [string] $ADAWTemplateSpecSubscriptionName
)

# Import Azure Modules
Import-Module Az.Resources

# Let this identity to connect to Azure and provision ADAW
$conn = Get-AutomationConnection -Name AzureRunAsConnection
$c = Connect-AzAccount -ServicePrincipal -Tenant $conn.TenantID -ApplicationId $conn.ApplicationID -CertificateThumbprint $conn.CertificateThumbprint

# Get ADAW Template Spec
$c = Set-AzContext -Subscription $ADAWTemplateSpecSubscriptionName
$tid = (Get-AzTemplateSpec -ResourceGroupName $ADAWTemplateSpecResourceGroup -Name $ADAWTemplateSpecName -Version $ADAWTemplateSpecVersion).Versions.Id

function New-RandomString {
    param(
        [Parameter(Mandatory = $false)]
        [switch] $convertToSecureString
    )

    $str =
    ([char[]]([char]65..[char]90) +
        ([char[]]([char]97..[char]122)) +
        0..9 +
        ([char[]]([char]33, 35, 36, 37, 38, 42, 43, 44, 45, 46, 58, 59, 60, 61, 62, 63, 64)) | sort { Get-Random })[0..13] -join ''
    
    if ($convertToSecureString.IsPresent) {
        ConvertTo-SecureString -String $str -AsPlainText -Force
    }
    else {
        $str
    }
}

function Merge-Hashtables {
    $output = @{}
    ForEach ($hashtable in ($input + $args)) {
        If ($hashtable -is [Hashtable]) {
            ForEach ($key in $hashtable.Keys) { $output.$key = $hashtable.$key }
        }
    }
    $output
}

# Generate user name and password for Azure SQL DB (users will not use them / know them)
$sqlServerLogin = New-RandomString
$sqlServerPassword = New-RandomString -ConvertToSecureString

# If tags are passed as string (assuming hashtable compatible syntax) - convert tags to hashtable
if ($targetResourceGroupTags -is [string] ) {
    $targetResourceGroupTags = Invoke-Expression $targetResourceGroupTags
}

# Switch Context to the Target Subscription
$c = Set-AzContext -Subscription $targetSubscription

# Try to get resource group - might or might not exists
$rg = Get-AzResourceGroup | where { $_.ResourceGroupName -EQ $targetResourceGroup }

# Create resource group if not exists and add or Update tags on Resource Group
if ($rg -eq $null) {
    $rg = New-AzResourceGroup -Name $targetResourceGroup -Location $targetResourceGroupLocation -Tag $targetResourceGroupTags 
}
else {
    $t = (Get-AzResourceGroup -Name $targetResourceGroup).Tags
    $targetResourceGroupTags = Merge-Hashtables $t $targetResourceGroupTags
    $t = Set-AzResourceGroup -Name $targetResourceGroup -Tag $targetResourceGroupTags
}

# Provision ADAW
New-AzResourceGroupDeployment -TemplateSpecId $tid -ResourceGroupName $targetResourceGroup -projectPrefix $projectPrefix -securityOwnerAADLogin $securityOwnerAADLogin -securityOwnerAADId $securityOwnerAADId -securityAlertEmail $securityAlertEmail -sqlServerLogin $sqlServerLogin -sqlServerPassword $sqlServerPassword -vNetPrefix $vNetPrefix -subnetControlPlanePrefix $subnetControlPlanePrefix -subnetDataPlanePrefix $subnetDataPlanePrefix -subnetPrivateLinkPrefix $subnetPrivateLinkPrefix -virtualApplianceIPAddress $virtualApplianceIPAddress -sqlServerDBSkuName $sqlServerDBSkuName -sqlServerDBTierName $sqlServerDBTierName -logRetentionInDays $logRetentionInDays
